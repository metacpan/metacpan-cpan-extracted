package Log::Dispatch::Configurator::AppConfig;

use strict;
use vars qw($VERSION);
$VERSION = '1.00';

use Log::Dispatch::Configurator;
use base qw(Log::Dispatch::Configurator);
use AppConfig;

sub new {
    my($class, $file, $section) = @_;
    my $self = bless { section => ($section ? "${section}_" : '') }, $class;
    if(ref $file && $file->isa('AppConfig')){
	$self->{config} = $file;
    }else{
	$self->{file}   = $file;
    }
    $self->parse_file;
    return $self;
}

sub parse_file {
    my $self = shift;

    my $section = $self->{section};
    my $config;
    if($self->{config}){
	$config = $self->{config};
    }
    else{ 
	$config = AppConfig->new({
	CREATE => 1,
	GLOBAL => {
	    ARGCOUNT => AppConfig::ARGCOUNT_ONE(),
	},
    });
	$config->file($self->{file});
    }
    $config->define("${section}dispatchers" => { DEFAULT => '' })    unless $config->varlist("^${section}dispatchers\$");
    $config->define("${section}format"      => { DEFAULT => undef }) unless $config->varlist("^${section}format\$");
    
    $self->{_config} = $config;
}

sub reload {
    my $self = shift;
    $self->parse_file;
}

sub _config { $_[0]->{_config} }

sub get_attrs_global {
    my $self = shift;
    my $section = $self->{section};
    return {
	format      => scalar $self->_config->get("${section}format"),
	dispatchers => [ split /\s+/, $self->_config->get("${section}dispatchers") ],
    };
}

sub get_attrs {
    my($self, $name) = @_;
    my $section = $self->{section};
    my $regex = "^$section$name" . '[\._]';
    my %var = $self->_config->varlist($regex);
    my %param = map {
        (my $key = $_) =~ s/$regex//;
        $key => $var{$_};
    } keys %var;
    return \%param;
}

1;
__END__

=head1 NAME

Log::Dispatch::Configurator::AppConfig - Configurator implementation with AppConfig

=head1 SYNOPSIS

  use Log::Dispatch::Config;
  use Log::Dispatch::Configurator::AppConfig;

  my $config = Log::Dispatch::Configurator::AppConfig->new('log.cfg');
  Log::Dispatch::Config->configure($config);

  # nearby piece of code
  my $log = Log::Dispatch::Config->instance;

=head1 DESCRIPTION

Log::Dispatch::Configurator::AppConfig is an implementation of
Log::Dispatch::Configurator using AppConfig format. Here is a sample
of config file.

  dispatchers = file screen

  file.class = Log::Dispatch::File
  file.min_level = debug
  file.filename = /path/to/log
  file.mode = append
  file.format = [%d] [%p] %m at %F line %L%n

  screen.class = Log::Dispatch::Screen
  screen.min_level = info
  screen.stderr = 1
  screen.format = %m

You can use ini style grouping.

  [file]
  class = Log::Dispatch::File
  min_level = debug

  [screen]
  class = Log::Dispatch::Screen
  min_level = info

If you use _ (underscore) in dispatcher name, something very B<bad>
may happen. It is safe when you avoid doing so.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Log::Dispatch::Config>, L<AppConfig>

=cut
