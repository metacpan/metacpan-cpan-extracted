package HTTP::Proxy::GreaseMonkey::ScriptHome;

use warnings;
use strict;
use Carp;
use File::Find;
use HTTP::Proxy::GreaseMonkey::Script;
use base qw( HTTP::Proxy::GreaseMonkey );

=head1 NAME

HTTP::Proxy::GreaseMonkey::ScriptHome - A directory of GreaseMonkey scripts

=head1 VERSION

This document describes HTTP::Proxy::GreaseMonkey::ScriptHome version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use HTTP::Proxy::GreaseMonkey::ScriptHome;
  
=head1 DESCRIPTION

Represents a directory containing a number of GreaseMonkey user scripts.

=head1 INTERFACE 

=head2 C<< add_dir >>

Add a directory that may contain user scripts. The directory will be
scanned recursively looking for files with the '.js' extension.

=cut

sub add_dir {
    my $self = shift;
    push @{ $self->{dirs} }, @_;
}

=head2 C<< begin >>

Begin filter processing. Rescans script directories adding / removing /
updating scripts as appropriate.

=cut

sub begin {
    my ( $self, $message ) = @_;

    $self->_reload;
    $self->SUPER::begin( $message );
}

sub _reload {
    my $self = shift;

    # Invasive superclass surgery follows. Look away if squeamish.

    my @files = $self->_walk;
    my @current = @{ $self->{script} || [] };
    $self->{script} = [];

    # Loop over all found scripts replacing any that have been updated,
    # removing any that have been deleted, adding any that are new,
    # maintaining original order.

    while ( my $f = shift @files ) {
        while ( @current && $f gt $current[0]->file ) {
            # Delete orphan
            shift @current;
        }

        if ( @current && $f eq $current[0]->file ) {
            # Match: updated?
            my $cur   = shift @current;
            my @nstat = stat $f or croak "Can't stat $f ($!)";
            my @ostat = $cur->stat;
            # If the script file hasn't changed recycle the current
            # script object else replace it with a new one.
            $self->add_script( $nstat[9] > $ostat[9] ? $f : $cur );
            print "Reloading $f\n"
              if $self->verbose && $nstat[9] > $ostat[9];
        }
        else {
            # New script
            $self->add_script( $f );
            print "Loading $f\n" if $self->verbose;
        }
    }
}

sub _walk {
    my $self  = shift;
    my @files = ();
    find(
        {
            wanted => sub {
                push @files, $_ if -f && /[.]js$/i;
            },
            no_chdir => 1,
        },
        @{ $self->{dirs} || [] }
    );
    return sort @files;
}

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
HTTP::Proxy::GreaseMonkey::ScriptHome requires no configuration files or
environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-http-proxy-greasemonkey@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
