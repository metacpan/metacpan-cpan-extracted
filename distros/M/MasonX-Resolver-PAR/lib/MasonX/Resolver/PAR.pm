package MasonX::Resolver::PAR;

$VERSION = '0.2';

use strict;

use Apache;
use Apache::Server;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use Params::Validate qw(:all);

use HTML::Mason::ComponentSource;
use MasonX::Component::ParBased;
use HTML::Mason::Resolver;
use base qw(HTML::Mason::Resolver);

use HTML::Mason::Exceptions (abbr => ['param_error']);

__PACKAGE__->valid_params
    (
     par_file => { parse => 'string', type => SCALAR },
     par_files_path => { parse => 'string', type => SCALAR, default=>'htdocs/' },
      par_static_directory_index => { type => ARRAYREF, default => [ qw( index.htm index.html ) ] },

    );

sub new {
    my $class    = shift;
    my $self     = $class->SUPER::new(@_);
    my $parfile  = $self->{par_file};
    my $filepath = $self->{par_files_path};
       $filepath.= '/' if ($filepath !~ /\/$/);
    my $zip = Archive::Zip->new($parfile);
    if ($zip) {
        die "No $filepath in $parfile" unless
	 $zip->memberNamed ($filepath); 
    } else {
       param_error "$parfile must be executable";
    } 
    $self->{par_files_path}=$filepath;
    return $self;
   }


# Internal method to retrieve a list of Archive::Zip members
#  representing the files requested. takes a regexp as input
sub _get_files {
    my ($self, $path) = @_;
    my $par=$self->{par_file};
    my $filepath=$self->{par_files_path};
    my $zip = Archive::Zip->new($par);
    if ($zip) {
      my @conf_members=$zip->membersMatching($filepath.$path);
      return @conf_members if @conf_members;
    }
return ;
}


# Internal method to retrieve a Archive::Zip member representing the file
sub _get_file {
    my ($self, $path) = @_;
    $path =~ s/^\///;
    my $par=$self->{par_file};
    my $filepath=$self->{par_files_path};
    my $zip = Archive::Zip->new($par);
    if ($zip) {
      my $conf_member=$zip->memberNamed($filepath.$path);
      return $conf_member if $conf_member;
    }
    return undef;
}

sub get_info {
    my ($self, $path) = @_;
    my $content=$self->_get_file($path);
    return unless $content;
    my ($last_mod) =$content->lastModTime;
    return unless $last_mod;
    my $base=$self->{par_file}; 
    $base =~ s/^.*\///;

    return
        HTML::Mason::ComponentSource->new
            ( 
              friendly_name => "$base$path",
              comp_id => "$base$path",
              last_modified => $last_mod,
	      comp_path => $path,
              comp_class => "MasonX::Component::ParBased",
              source_callback => sub { $self->_get_source($path) },
#	      extra => { comp_root => 'par' },
            );
}

sub _get_source {
    my ($self, $path) = @_;
    my $content=$self->_get_file($path);
    return unless $content;
    return $content->contents;
}

sub glob_path {
    my $self = shift;
    my $pattern = shift;

    $pattern =~~ s/\*/\[\/\]\*/g;

    return
        $self->_get_files($pattern);
}

# Translate apache request object to a component path
sub apache_request_to_comp_path {

    my $self = shift;
    my $r = shift;
#FIXME: These should be imported from Apache's settings
    my @indices=@{$self->{par_static_directory_index}};
    #we base this on path_info
    my $path = ( $r->path_info ? $r->path_info : "/" );
    my $file=$self->_get_file($path);
    if ($file) {
      return $path unless $file->isDirectory; 
      if ($file->isDirectory()) { #then we add index path
        $path.= '/' if ($path !~ /\/$/);
        foreach my $index (@indices) {
  	  return $path.$index if $self->_get_file($path.$index);
        }
      }
    return undef;
    }
    return $path;
}

1;

__END__

=head1 NAME

MasonX::Resolver::PAR - Get mason components from a PAR file

=head1 SYNOPSIS

        (Inside a web.conf)	
	PerlModule HTML::Mason::ApacheHandler
	PerlModule MasonX::Resolver::PAR
        <Location /myapp>
	  SetHandler perl-script
          PerlSetVar MasonParStaticDirectoryIndex index.htm
	  PerlAddVar MasonParStaticnDirectoryIndex index.html
          PerlSetVar MasonParFile ##PARFILE##
          PerlSetVar MasonResolverClass MasonX::Resolver::PAR
	  PerlHandler HTML::Mason::ApacheHandler
        </Location>

=head1 DESCRIPTION

This is a custom Mason Resolver which loads it's content from a PAR
archive. This is meant to be used in conjunction with Apache::PAR. Read
the description for this module first. The web.conf above should be inside
the par archive as specified by Apache::PAR. It will be appended to your apache conf.

=head1 Parameters

=over 4

=item MasonParStaticDirectoryIndex 

allows us to emulate mod_dir. It defaults to qw(index.html index.htm).

=item MasonParFile *required*

should point to the par file we are reading from. Apache::PAR provides the 
##PARFILE## functionality. note that this can also be passed to the 
ApacheHandler constructor as par_file.

=item MasonParFilesPath

Where in the par archive to read mason components from. Defaults to 'htdocs/',
ApacheHandler constructor parameter is par_files_path.

=head1 SEE ALSO

PAR, Apache::PAR, HTML::Mason::Resolver
