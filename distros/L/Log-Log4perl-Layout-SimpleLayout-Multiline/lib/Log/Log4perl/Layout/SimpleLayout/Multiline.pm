#!/usr/bin/perl

package Log::Log4perl::Layout::SimpleLayout::Multiline;
use base qw/Log::Log4perl::Layout::SimpleLayout/;

use strict;
use warnings;

our $VERSION = '0.02';

sub render {
	my $self = shift;
	my $output = $self->SUPER::render(@_);

	if ( $output =~ /([A-Z]+ - )/ ) {
        my $spaces = ' ' x length($1);
        $output =~ s/(\r?\n|\r)(?!$)/$1$spaces\t/g;
    }

	$output;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Log::Log4perl::Layout::SimpleLayout::Multiline - Handle multiple lines with the
L<Log::Log4perl::Layout::SimpleLayout>

=head1 SYNOPSIS

    # see Log::Log4perl

=head1 DESCRIPTION

This is a drop in replacement for L<Log::Log4perl::Layout::SimpleLayout> that
formats multiple lines with indentation aligned according to the metadata
prefix that L<Log::Log4perl::Layout::SimpleLayout> adds.

=head1 SEE ALSO

L<Log::Log4perl>

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005, 2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
