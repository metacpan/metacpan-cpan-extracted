#!/usr/bin/perl -w

package Log::Delimited;

use strict;
use vars qw(@EXPORT @EXPORT_OK @ISA $LOG_BASE_DIR $VERSION);

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw(log);
@EXPORT_OK = qw($LOG_BASE_DIR);

use File::Path qw(mkpath);
use Storable qw(freeze);
use Sys::Hostname qw(hostname);

$LOG_BASE_DIR = "/tmp/logs";
$VERSION = '0.90';

sub O_RDWR () { 2 }
sub O_CREAT () { 64 }


sub new {
  my $type  = shift;
  my @PASSED_ARGS = (ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
  my @DEFAULT_ARGS = (
    base_dir      => $LOG_BASE_DIR,

    delimiter     => '|',
    log_cols      => '',

    # log_info is an array ref of the info you would like to log
    log_info      => '',
    log_name      => '',
    log_node      => 'main',

    no_hostname   => 0,
    no_pid        => 0,
    no_time       => 0,
  );
  my %ARGS = (@DEFAULT_ARGS, @PASSED_ARGS);
  foreach(qw(log_node log_name)) {
    unless($ARGS{$_}) {
      ($ARGS{$_}) = ($0 =~ m@.*/(.+)@) || $0;
    }
  }
  my $self = bless \%ARGS, $type;
  die "need a \$self->{log_name}" unless($self->{log_name});
  $self->handle_dirs;
  $self->mkpath_dirs;
  return $self;
}

sub URLEncode {
  my $arg = shift;
  my ($ref,$return) = ref($arg) ? ($arg,0) : (\$arg,1) ;

  $$ref =~ s/([^\w\.\ -])/sprintf("%%%02X",ord($1))/eg;
  $$ref =~ tr/\ /+/;

  return $return ? $$ref : '';
}

sub handle_dirs {
  my $self = shift;
  return if($self->{handled_dirs});
  die "need a \$self->{base_dir}" unless($self->{base_dir});
  die "need a \$self->{log_name}" unless($self->{log_name});
  $self->{log_dir}      ||= "$self->{base_dir}/$self->{log_node}";
  $self->{log_filename} ||= "$self->{log_dir}/$self->{log_name}";
  $self->{zip_filename} ||= "$self->{log_dir}/$self->{log_name}.gz";
  $self->{handled_dirs} = 1;
}

sub mkpath_dirs {
  my $self = shift;
  return if($self->{mkpathd});
  foreach(keys %{$self}) {
    next unless(/_dir$/ && $self->{$_} =~ m@^/@);
    mkpath ($self->{$_}) unless(-d $self->{$_});
    die "couldn't mkpath $self->{$_}" unless(-d $self->{$_});
  }
  $self->{mkpathd} = 1;
}

sub handle_log_cols {
  my $self = shift;
  if(ref $self->{log_cols} eq 'ARRAY' && !$self->{cols_string}) {
    unshift @{$self->{log_cols}}, 'hostname' unless($self->{unshifted_hostname} || $self->{no_hostname});
    unshift @{$self->{log_cols}}, 'pid' unless($self->{unshifted_pid} || $self->{no_pid});
    unshift @{$self->{log_cols}}, 'time' unless($self->{unshifted_time} || $self->{no_time});
    $self->{cols_string} = join($self->{delimiter}, @{$self->{log_cols}});
  } else {
    $self->{cols_string} = $self->{log_cols};
  }
}

sub handle_log_info {
  my $self = shift;
  my $ref = shift;
  die "\$self->{log_info} is required" unless($ref);
  die "\$self->{log_info} needs to be an array ref" unless(ref $ref && ref $ref eq 'ARRAY');
  unshift @{$ref}, hostname unless($self->{no_hostname});
  unshift @{$ref}, $$ unless($self->{no_pid});
  unshift @{$ref}, time unless($self->{no_time});
}

sub ref2string {
  my $self = shift;
  my $ref = shift;
  unless(ref $ref && ref $ref eq 'ARRAY') {
    $ref = [$ref];
  }
  my @this_array = @{$ref};
  foreach(@this_array) {
    $_ = '' unless((defined $_) && length $_);
    if(ref $_ && ref $_ eq 'HASH') {
      $_ = freeze $_;
    }
    URLEncode \$_ unless($self->{no_URLEncode});
  }
  my $string = join($self->{delimiter}, @this_array);
  return $string;
}

sub log {
  my $self = shift;
  die "need a " . __PACKAGE__ . " object" unless(ref $self eq __PACKAGE__);

  open(LOG, ">>$self->{log_filename}") || die "couldn't opendir $self->{log_filename}: $!";
  if(!-s $self->{log_filename}) {
    if($self->{log_cols}) {
      $self->handle_log_cols;
      print LOG "$self->{cols_string}\n";
    }
  }

  unless(ref $self->{log_info}[0] eq 'ARRAY') {
    $self->{log_info} = [$self->{log_info}];
  }

  for(my $i=0;$i<@{$self->{log_info}};$i++) {
    my (@this_array) = @{$self->{log_info}[$i]};
    $self->handle_log_info(\@this_array);
    my $this_string = $self->ref2string(\@this_array);
    print LOG "$this_string\n";
  }
  close(LOG);
  delete $self->{log_info};
}

sub wipe {
  my $self = shift;
  if(-e $self->{log_filename}) {
    return unlink $self->{log_filename};
  }
}

sub zip {
  my $self = shift;
  die "need a \$self->{log_filename}" unless($self->{log_filename});
  die "need a \$self->{zip_filename}" unless($self->{zip_filename});
  return unless(-s $self->{log_filename});
  system("gzip -c < $self->{log_filename} > $self->{zip_filename}");
}

sub unzip {
  my $self = shift;
  die "need a \$self->{log_filename}" unless($self->{log_filename});
  die "need a \$self->{zip_filename}" unless($self->{zip_filename});
  return unless(-s $self->{zip_filename});
  system("gzip -dc < $self->{zip_filename} > $self->{log_filename}");
}

sub log_zipped {
  my $self = shift;
  $self->unzip;
  $self->log;
  $self->zip;
  $self->wipe;
}

1;

__END__

=head1 NAME

Log::Delimited - simple module to help log results

=head1 SYNOPSIS

#!/usr/bin/perl -w

use strict;
use Log::Delimited;

my $log = Log::Delimited->new({
  log_cols => ['url', 'step', 'elapsed'],
  log_info =>  ['http://slap.com/cgi-bin/slow_script', 'step 1', '99993.0923'],
})->log;

$log->{log_info} =  ['http://slap.com/cgi-bin/slow_script', 'step 2', '8.3240'];
$log->log;

=head1 DESCRIPTION

  Log is sort of a dumb program that leads to sort of smart stuff.  

It takes some columns ('this', 'that', 'else'), some data 
('rulz', 'rocks!', 'do something') and a delimiter ('|'), 
and makes a file that looks like this

this|that|else

my_hostname|12342|1000204952|rulz|rocksrocks%21|do+something

the first row is a join($delimiter, @column_names), the second (in a little pseudo code) forms 

@data = ($hostname, $pid, time, $array_ref_of_your_passed_data)

then forms the row with join($delimiter, URLEncode(@data)).  By the way, you can turn off the hostname, pid and time inclusion,
but in most applications, they have come in handy.  To turn them off just set which applies from below

  $self->{no_hostname} = 1;
  $self->{no_pid} = 1;
  $self->{no_time} = 1;

To turn off Url encoding, just set

  $self->{no_URLEncode} = 1;

In this document, $self is a Log::Delimited object.

The log directory is

$self->{base_dir}  = "/tmp/logs";
$self->{log_dir} ||= "$self->{base_dir}/$self->{log_node}";

Log uses the last part of your script name ($0) for the log_node if you don't pass one.

The log file is

$self->{log_filename} ||= "$self->{log_dir}/$self->{log_name}";

Log uses the last part of your script name ($0) for the log_name if you don't pass one.


Since logs can get to be quite large, you can easily zip, by doing

$self->zip;

If you have a large log, where size is a bigger issue than speed you can do

$self->log_zipped;

which will result in just a zipped log file.

=head1 EXAMPLE

#!/usr/bin/perl -w

use strict;
use Log::Delimited;

my $log = Log::Delimited->new({
  log_node => 'slap',
  log_name => 'cool_path',
  log_cols => ['url', 'step', 'elapsed'],
  log_info =>  ['http://slap.com/cgi-bin/slow_script', 'step 1', '99993.0923'],
})->log;

$log->{log_info} =  ['http://slap.com/cgi-bin/slow_script', 'step 2', '8.3240'];
$log->log;

=head1 ZIP EXAMPLE

#!/usr/bin/perl -w

use strict;
use Log::Delimited;

my $log = Log::Delimited->new({
  log_cols => ['url', 'step', 'elapsed'],
});
$log->{log_info} = ['http://slap.com/cgi-bin/slow_script', 'step 1', '99993.0923'];
$log->zipped_log;

=head1 AUTHOR

Earl Cahill, cpan@spack.net

=cut
