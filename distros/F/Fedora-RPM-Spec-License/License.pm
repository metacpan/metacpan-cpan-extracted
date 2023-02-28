package Fedora::RPM::Spec::License;

use strict;
use warnings;

use Class::Utils qw(set_params);
use English;
use Error::Pure qw(err);
use License::SPDX;
use List::Util qw(none);
use Parse::RecDescent;
use Readonly;

my $GRAMMAR1 = <<'END';
	start: expression
	expression: and_expr 'or' expression {
		[$item[1], '||', $item[3]],
	} | and_expr
	and_expr: brack_expression 'and' and_expr {
		[$item[1], '&&', $item[3]],
	} | brack_expression
	brack_expression: '(' expression ')' {
		$item[2];
	} | identifier
	identifier: /([\w\s\.\+]+?)(?=(?:\s*and|\s*or|\(|\)|$))/ {
		$item[1];
	}
END
my $GRAMMAR2 = <<'END';
	start: expression
	expression: and_expr 'OR' expression {
		[$item[1], '||', $item[3]],
	} | and_expr
	and_expr: with_expr 'AND' and_expr {
		[$item[1], '&&', $item[3]],
	} | with_expr
	with_expr: brack_expression 'WITH' exception {
		[$item[1], 'with', $item[3]],
	} | brack_expression
	brack_expression: '(' expression ')' {
		$item[2];
	} | identifier
	identifier: /[\w\-\.]+/ {
		if (! License::SPDX->new->check_license($item[1])) {
			die "License '$item[1]' isn't SPDX license.\n";
		}
		$item[1];
	}
	exception: /[\w\-\.]+/ {
		if (! License::SPDX->new->check_exception($item[1])) {
			die "License '$item[1]' isn't SPDX license exception.\n";
		}
		$item[1];
	}
END

our $VERSION = 0.03;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	$self->{'spdx'} = License::SPDX->new;

	$self->{'parser1'} = Parse::RecDescent->new($GRAMMAR1);
	$self->{'parser2'} = Parse::RecDescent->new($GRAMMAR2);

	return $self;
}

sub exceptions {
	my $self = shift;

	if (! $self->{'result'}->{'status'}) {
		err 'No Fedora license string processed.';
	}

	my @ret = sort @{$self->{'result'}->{'exceptions'}};

	return @ret;
}

sub format {
	my $self = shift;

	if (! $self->{'result'}->{'status'}) {
		err 'No Fedora license string processed.';
	}

	return $self->{'result'}->{'format'};
}

sub licenses {
	my $self = shift;

	if (! $self->{'result'}->{'status'}) {
		err 'No Fedora license string processed.';
	}

	my @ret = sort @{$self->{'result'}->{'licenses'}};

	return @ret;
}

sub parse {
	my ($self, $fedora_license_string) = @_;

	$self->_init;

	$self->{'result'}->{'input'} = $fedora_license_string;

	if ($fedora_license_string =~ m/AND/ms
		|| $fedora_license_string =~ m/OR/ms
		|| $fedora_license_string =~ m/\s+WITH\s+/ms) {

		$self->{'result'}->{'format'} = 2;
		$self->_process_format_2($fedora_license_string);
	} elsif ($fedora_license_string =~ m/and/ms
		|| $fedora_license_string =~ m/or/ms) {

		$self->{'result'}->{'format'} = 1;
		$self->_process_format_1($fedora_license_string);
	} else {
		if ($self->{'spdx'}->check_license($fedora_license_string)) {
			$self->{'result'}->{'format'} = 2;
			$self->_process_format_2($fedora_license_string);
		} else {
			$self->{'result'}->{'format'} = 1;
			$self->_process_format_1($fedora_license_string);
		}
	}
	$self->{'result'}->{'status'} = 1;

	$self->_unique($self->{'result'}->{'res'});

	return;
}

sub reset {
	my $self = shift;

	$self->_init;

	return;
}

sub _init {
	my $self = shift;

	$self->{'result'} = {
		'exceptions' => [],
		'format' => undef,
		'input' => undef,
		'licenses' => [],
		'status' => 0,
		'res' => undef,
	};

	return;
}

sub _process_format_1 {
	my ($self, $fedora_license_string) = @_;

	$self->{'result'}->{'res'} = $self->{'parser1'}->start($fedora_license_string);

	return;
}

sub _process_format_2 {
	my ($self, $fedora_license_string) = @_;

	eval {
		$self->{'result'}->{'res'} = $self->{'parser2'}->start($fedora_license_string);
	};
	if ($EVAL_ERROR) {
		err $EVAL_ERROR;
	}

	return;
}

sub _unique {
	my ($self, $value) = @_;

	if (ref $value eq '') {
		if ($value eq 'with') {
			$self->{'_exception'} = 1;
		}
		if ($value ne '||' && $value ne '&&' && $value ne 'with') {
			if ($self->{'_exception'}) {
				push @{$self->{'result'}->{'exceptions'}}, $value;
				$self->{'_exception'} = 0;
			} else {
				push @{$self->{'result'}->{'licenses'}}, $value;
			}
		}
	} elsif (ref $value eq 'ARRAY') {
		foreach my $item (@{$value}) {
			$self->_unique($item);
		}
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Fedora::RPM::Spec::License - Class for handle Fedora license string.

=head1 SYNOPSIS

 use Fedora::RPM::Spec::License;

 my $obj = Fedora::RPM::Spec::License->new(%params);
 my @exceptions = $obj->exceptions;
 my $fedora_license_format = $obj->format;
 my @licenses = $obj->licenses;
 $obj->parse($fedora_license_string);
 $obj->reset;

=head1 DESCRIPTION

Fedora license string is used in Fedora RPM spec files in License field. There
are two versions of this string. One is old version and new one with SPDX
identifiers.

=head1 METHODS

=head2 C<new>

 my $obj = Fedora::RPM::Spec::License->new(%params);

Constructor.

Returns instance of object.

=head2 C<exceptions>

 my @exceptions = $obj->exceptions;

Get exceptions used in the Fedora license string sorted alphabetically.

Returns array of strings.

=head2 C<format>

 my $fedora_license_format = $obj->format;

Get Fedora license string format.
Possible values:

 1 - Old RPM Fedora format.
 2 - New RPM Fedora format with SPDX license ids.

Returns number.

=head2 C<licenses>

 my @licenses = $obj->licenses;

Get licenses used in the Fedora license string sorted alphabetically.

Returns array of strings.

=head2 C<parse>

 $obj->parse($fedora_license_string);

Parse Fedora license string and set object internal structures.
If string is valid for format 1 and 2 as well, format 2 is preferred. Example is 'MIT'
license string.

Returns undef.

=head2 C<reset>

 $obj->reset;

Reset object.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 format():
         No Fedora license string processed.

 licenses():
         No Fedora license string processed.

 parse():
         License '%s' isn't SPDX license.
         License '%s' isn't SPDX license exception.

=head1 EXAMPLE

=for comment filename=parse_fedora_license_string.pl

 use strict;
 use warnings;

 use Fedora::RPM::Spec::License;

 if (@ARGV < 1) {
         print STDERR "Usage: $0 fedora_license_string\n";
         exit 1;
 }
 my $fedora_license_string = $ARGV[0];

 # Object.
 my $obj = Fedora::RPM::Spec::License->new;

 # Parse license.
 $obj->parse($fedora_license_string);

 # Print out.
 print "Fedora license string: $fedora_license_string\n";
 print 'Format: '.$obj->format."\n";
 print "Contain licenses:\n";
 print join "\n", map { '- '. $_ } $obj->licenses;
 print "\n";
 if ($obj->exceptions) {
         print "Contain exceptions:\n";
         print join "\n", map { '- '. $_ } $obj->exceptions;
         print "\n";
 }

 # Output with 'MIT' input:
 # Fedora license string: MIT
 # Format: 2
 # Contain licenses:
 # - MIT

 # Output with 'MIT AND FSFAP' input:
 # Fedora license string: MIT AND FSFAP
 # Format: 2
 # Contain licenses:
 # - FSFAP
 # - MIT

 # Output with '(GPL+ or Artistic) and Artistic 2.0 and (MIT or GPLv2)' input:
 # Fedora license string: (GPL+ or Artistic) and Artistic 2.0 and (MIT or GPLv2)
 # Format: 1
 # Contain licenses:
 # - Artistic
 # - Artistic 2.0
 # - GPL+
 # - GPLv2
 # - MIT

 # Output with 'LGPL-3.0-only WITH LGPL-3.0-linking-exception' input:
 # Fedora license string: LGPL-3.0-only WITH LGPL-3.0-linking-exception
 # Format: 2
 # Contain licenses:
 # - LGPL-3.0-only
 # Contain exceptions:
 # - LGPL-3.0-linking-exception

=head1 DEPENDENCIES

L<Class::Utils>,
L<English>,
L<Error::Pure>,
L<License::SPDX>,
L<List::Util>,
L<Parse::RecDescent>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<rpm-spec-license>

Tool for working with RPM spec file licenses.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Fedora-RPM-Spec-License>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
