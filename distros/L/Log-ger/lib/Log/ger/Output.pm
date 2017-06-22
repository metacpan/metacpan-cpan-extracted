package Log::ger::Output;

our $DATE = '2017-06-21'; # DATE
our $VERSION = '0.004'; # VERSION

use strict;
use warnings;

sub set {
    my $pkg = shift;

    require Log::ger::Util;
    Log::ger::Util::set_output(@_);
}

sub import {
    my $pkg = shift;
    if (@_) {
        set($pkg, @_);
    }
}

1;
# ABSTRACT: Set logging output

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output - Set logging output

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use Log::ger::Output;
 Log::ger::Output->set('Screen', use_color=>1, ...);

or:

 use Log::ger::Output Screen => (
     use_color => 1,
     ...
 );

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

Modelled after L<Log::Any::Adapter>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
