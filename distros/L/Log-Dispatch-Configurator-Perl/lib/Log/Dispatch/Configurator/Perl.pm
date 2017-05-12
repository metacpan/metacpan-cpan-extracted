package Log::Dispatch::Configurator::Perl;
use strict;
use warnings;
use Carp qw/croak/;
use parent 'Log::Dispatch::Configurator';

our $VERSION = '0.0132';

sub new {
    my ($class, $file) = @_;

    my $self = bless { file => $file }, $class;
    $self->exec_file;
    return $self;
}


sub exec_file {
    my $self = shift;

    my $config = do $self->{file}
                    or croak "could not load conf file: $self->{file}";
    $self->{'_config'} = $config;
}


sub reload {
    $_[0]->exec_file;
}


sub get_attrs_global {
    my $self = shift;

    +{
        format      => undef,
        dispatchers => (exists $self->{'_config'}{'dispatchers'})
                            ? $self->{'_config'}{'dispatchers'} : [],
    };
}


sub get_attrs {
      $_[0]->{'_config'}{$_[1]};
}

1;

__END__

=head1 NAME

Log::Dispatch::Configurator::Perl - Configurator implementation with Perl Code Style

=head1 SYNOPSIS

  use Log::Dispatch::Config;
  use Log::Dispatch::Configurator::Perl;

  my $config = Log::Dispatch::Configurator::Perl->new('conf.pl');
  Log::Dispatch::Config->configure($config);

  # nearby piece of code
  my $log = Log::Dispatch::Config->instance;

=head1 DESCRIPTION

Log::Dispatch::Configurator::Perl is an implementation of
Log::Dispatch::Configurator using Perl Code Style. Here is a sample
of config file.

    +{
        dispatchers => [qw/file screen/],
        file => +{
            class     => 'Log::Dispatch::File',
            min_level => 'debug',
            filename  => 't/log.out',
            mode      => 'append',
            format    => '[%d] [%p] %m at %F line %L',
        },
        screen => +{
            class     => 'Log::Dispatch::Screen',
            min_level => 'info',
            stderr    => 1,
            format    => '%m %%',
        },
    }

=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>

=head1 SEE ALSO

L<Log::Dispatch::Configurator::AppConfig>, L<Log::Dispatch::Config>, L<AppConfig>

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
