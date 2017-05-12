package Log::Dispatch::Configurator::YAML;
use base 'Log::Dispatch::Configurator';
use strict;
use warnings;

our $VERSION = '0.03';

use YAML ();


sub new {
    my($class, $file) = @_;
    my $self = bless { file => $file }, $class;
    $self->parse_file;
    return $self;
}


sub parse_file {
    my $self = shift;
    my $file = $self->{'file'};

    my $config = YAML::LoadFile($file);
    $self->{'_config'} = $config;
}


sub reload {
    my $self = shift;
    $self->parse_file;
}


sub get_attrs_global {
    my $self = shift;
    my $dispatchers
        = exists $self->{'_config'}->{'dispatchers'} ? $self->{'_config'}->{'dispatchers'} : [];
    return {
        format => undef,
        dispatchers => $dispatchers,
    };
}


sub get_attrs {
      my($self, $name) = @_;
      return $self->{'_config'}->{$name};
}



1;

__END__

=head1 NAME

Log::Dispatch::Configurator::YAML - Configurator implementation with YAML

=head1 SYNOPSIS

  use Log::Dispatch::Config;
  use Log::Dispatch::Configurator::YAML;

  my $config = Log::Dispatch::Configurator::YAML->new('log.yml');
  Log::Dispatch::Config->configure($config);

  # nearby piece of code
  my $log = Log::Dispatch::Config->instance;

=head1 DESCRIPTION

Log::Dispatch::Configurator::YAML is an implementation of
Log::Dispatch::Configurator using YAML format. Here is a sample
of config file.

 ---
 dispatchers:
   - file
   - screen

 file:
   class: Log::Dispatch::File
   min_level: debug
   filename: /path/to/log
   mode: append
   format: '[%d] [%p] %m at %F line %L%n'

 screen:
   class: Log::Dispatch::Screen
   min_level: info
   stderr: 1
   format: '%m'

=head1 SEE ALSO

L<Log::Dispatch::Configurator::AppConfig>, L<Log::Dispatch::Config>, L<AppConfig>

=head1 AUTHOR

Florian Merges E<lt>fmerges@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Florian Merges

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
