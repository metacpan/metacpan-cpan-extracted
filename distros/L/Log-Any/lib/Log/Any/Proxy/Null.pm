use 5.008001;
use strict;
use warnings;

package Log::Any::Proxy::Null;

# ABSTRACT: Log::Any generator proxy for no adapters
our $VERSION = '1.710';

use Log::Any::Adapter::Util ();
use Log::Any::Proxy;
our @ISA = qw/Log::Any::Proxy/;

# Null proxy objects waiting for inflation into regular proxy objects
my @nulls;

sub new {
    my $obj = shift->SUPER::new( @_ );
    push @nulls, $obj;
    return $obj;
}

sub inflate_nulls {
    bless shift( @nulls ), 'Log::Any::Proxy' while @nulls;
}

my %aliases = Log::Any::Adapter::Util::log_level_aliases();

# Set up methods/aliases and detection methods/aliases
foreach my $name ( Log::Any::Adapter::Util::logging_methods(), keys(%aliases) )
{
    my $namef       = $name . "f";
    my $super_name  = "SUPER::" . $name;
    my $super_namef = "SUPER::" . $namef;
    no strict 'refs';
    *{$name} = sub {
        return unless defined wantarray;
        return shift->$super_name( @_ );
    };
    *{$namef} = sub {
        return unless defined wantarray;
        return shift->$super_namef( @_ );
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Proxy::Null - Log::Any generator proxy for no adapters

=head1 VERSION

version 1.710

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

David Golden <dagolden@cpan.org>

=item *

Doug Bell <preaction@cpan.org>

=item *

Daniel Pittman <daniel@rimspace.net>

=item *

Stephen Thirlwall <sdt@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jonathan Swartz, David Golden, and Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
