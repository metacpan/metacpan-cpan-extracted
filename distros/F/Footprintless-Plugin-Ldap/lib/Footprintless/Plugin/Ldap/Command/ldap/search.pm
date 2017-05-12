use strict;
use warnings;

package Footprintless::Plugin::Ldap::Command::ldap::search;
$Footprintless::Plugin::Ldap::Command::ldap::search::VERSION = '1.00';
# ABSTRACT: search an ldap directory
# PODNAME: Footprintless::Plugin::Ldap::Command::ldap::search;

use parent qw(Footprintless::App::Action);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ( $self, $opts, $args ) = @_;

    $logger->info('Performing search...');
    $logger->debugf( 'options=%s', $self->{options} );
    eval {
        $self->{ldap}->connect()->bind();
        my @entries = $self->{ldap}->search_for_list( $self->{options} );
        my $index   = 0;
        foreach my $entry (@entries) {
            print("------------------------------------------------------------------------\n");
            print("Search Result Entry $index\n");
            $entry->dump();
            $index++;
        }
        print("------------------------------------------------------------------------\n");
        print("found $index matche(s).\n");
    };
    my $error = $@;
    eval { $self->{ldap}->disconnect() };
    die($error) if ($error);
}

sub opt_spec {
    return (
        [ 'attr=s@',  'attribute to include' ],
        [ 'base=s',   'base dn' ],
        [ 'filter=s', 'filter' ],
        [ 'scope=s',  'search scope' ],
    );
}

sub usage_desc {
    return 'fpl ldap LDAP_COORD search %o';
}

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    eval { $self->{ldap} = $self->{footprintless}->ldap( $self->{coordinate} ); };
    $self->usage_error("invalid coordinate [$self->{coordinate}]: $@") if ($@);

    $self->{options} = {
        attrs => $opts->{attr} || [ '*', '+' ],
        filter => $opts->{filter} || '(objectClass=*)',
        scope  => $opts->{scope}  || 'one',
        ( $opts->{base} ? ( base => $opts->{base} ) : () ),
    };
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Ldap::Command::ldap::search; - search an ldap directory

=head1 VERSION

version 1.00

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless::Plugin::Ldap|Footprintless::Plugin::Ldap>

=back

=for Pod::Coverage execute opt_spec usage_desc validate_args

=cut
