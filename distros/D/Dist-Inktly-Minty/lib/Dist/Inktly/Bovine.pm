use 5.010001;
use strict;
use warnings;

package Dist::Inktly::Bovine;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

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

use Moo;
use Types::Common qw( -types -sigs );
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
<https://github.com/{lc $author->{cpanid}}/p5-{lc URI::Escape::uri_escape($dist_name)}/issues>.

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
	:runtime-requirement    [ :on "perl 5.010001"^^:CpanId ];
	:runtime-requirement    [ :on "Moo 2.000000"^^:CpanId ];
	:runtime-requirement    [ :on "Types::Standard 2.000000"^^:CpanId ];
	:runtime-requirement    [ :on "namespace::autoclean 0.12"^^:CpanId ];
	:test-requirement       [ :on "Test2::V0"^^:CpanId ];
	:test-requirement       [ :on "Test2::Tools::Spec"^^:CpanId ];
	:test-requirement       [ :on "Test2::Require::AuthorTesting"^^:CpanId ];
	:test-requirement       [ :on "Test2::Require::Module"^^:CpanId ];
	:develop-recommendation [ :on "Dist::Inkt 0.001"^^:CpanId ];
	.
EOF

	return $class->SUPER::_get_template(@_);
}

1;

=head1 NAME

Dist::Inktly::Bovine - create distributions that will use Dist::Inkt and Moo

=head1 SYNOPSIS

  distinkt-mint --maker=Dist::Inktly::Bovine Local::Example::Useful

=head1 DESCRIPTION

This class inherits from L<Dist::Inktly::Minty>.

=head1 SEE ALSO

L<Dist::Inkt>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
