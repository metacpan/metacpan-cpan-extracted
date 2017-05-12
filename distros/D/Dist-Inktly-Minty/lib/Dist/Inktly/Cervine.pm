use 5.010001;
use strict;
use warnings;

package Dist::Inktly::Cervine;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Text::Template;

use base 'Dist::Inktly::Minty';

sub _get_template
{
	my $class = shift;
	my ($key) = @_;
	
	return 'Text::Template'->new(-type=>'string', -source=><<'EOF') if $key eq 'module';
COMMENCE module
use 5.010001;
use strict;
use warnings;

package {$module_name};

our $AUTHORITY = 'cpan:{uc $author->{cpanid}}';
our $VERSION   = '{$version}';

use Moose;
use Types::Standard -types;
use namespace::autoclean;

1;

{}__END__

{}=pod

{}=encoding utf-8

{}=head1 NAME

{$module_name} - {$abstract}

{}=head1 SYNOPSIS

{}=head1 DESCRIPTION

{}=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue={URI::Escape::uri_escape($dist_name)}>.

{}=head1 SEE ALSO

{}=head1 AUTHOR

{$author->{name}} E<lt>{$author->{mbox}}E<gt>.

{}=head1 COPYRIGHT AND LICENCE

{$licence->notice}

{}=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

EOF

	return 'Text::Template'->new(-type=>'string', -source=><<'EOF') if $key eq 'meta/makefile.pret';
# This file provides instructions for packaging.

@prefix : <http://ontologi.es/doap-deps#>.

`{$dist_name}`
	:runtime-requirement    [ :on "Moose 2.0800"^^:CpanId ];
	:runtime-requirement    [ :on "Types::Standard 0.022"^^:CpanId ];
	:runtime-requirement    [ :on "namespace::autoclean 0.12"^^:CpanId ];
	:test-requirement       [ :on "Test::More 0.96"^^:CpanId ];
	:develop-recommendation [ :on "Dist::Inkt 0.001"^^:CpanId ];
	.
EOF

	return $class->SUPER::_get_template(@_);
}

1;

=head1 NAME

Dist::Inktly::Cervine - create distributions that will use Dist::Inkt and Moose

=head1 SYNOPSIS

  distinkt-mint --maker=Dist::Inktly::Cervine Local::Example::Useful

=head1 DESCRIPTION

This class inherits from L<Dist::Inktly::Minty>.

=head1 SEE ALSO

L<Dist::Inkt>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
