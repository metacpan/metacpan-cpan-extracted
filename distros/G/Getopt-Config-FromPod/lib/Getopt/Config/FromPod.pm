package Getopt::Config::FromPod;

use strict;
use warnings;

# ABSTRACT: Extract getopt configuration from POD
our $VERSION = 'v0.0.3'; # VERSION

package Getopt::Config::FromPod::Extractor;

use strict;
use warnings;

use parent qw(Pod::Simple);

sub new
{
	my ($ref, %args) = @_;
	my $class = ref $ref || $ref;
	my $self = bless Pod::Simple::new($class, %args), $class;
	my $tag = $args{-tag} || 'getopt';
	$self->{_TAG} = $tag;
	$self->accept_targets($tag);
	return $self;
}

sub _handle_element_start
{
	my ($parser, $element_name, $attr) = @_;
	if($element_name eq 'Document') {
		$parser->{_RESULT} = [];
	}
	if(($element_name eq 'for' || $element_name eq 'begin') && $attr->{target} eq $parser->{_TAG}) {
		$parser->{_IN_TARGET} = 1;
	}
}

sub _handle_element_end
{
	my ($parser, $element_name, $attr) = @_;
	if($element_name eq 'for' || ($element_name eq 'end' && $attr->{target} eq $parser->{_TAG})) {
		$parser->{_IN_TARGET} = 0;
	}
}

sub _handle_text
{
	my ($parser, $text) = @_;
	push @{$parser->{_RESULT}}, eval $text if $parser->{_IN_TARGET}; ## no critic (ProhibitStringyEval)
}

package Getopt::Config::FromPod;

use Carp;

sub new
{
	my $self = shift;
	my $class = ref $self || $self;
	return bless { _ARG => \@_ }, $class;
}

sub _extract
{
	my ($self, %args) = @_;
	%args = (@{$self->{_ARG}}, %args);
	my $parser = Getopt::Config::FromPod::Extractor->new(%args);
	my $file = $args{-file};
	$args{-package} ||= 'main';
	if(! defined $file) {
		my $idx = 0;
		my @caller;
		while(@caller = caller($idx++)) {
			if($caller[0] eq $args{-package}) {
				$file = $caller[1];
				last;
			}
		}
		confess "Target module not found" if ! defined $file;
		# At least, in PAR environment, this adjustment is necessary.
		if(! -f $file) {
			for my $inc (@INC) {
				if(-f "$inc/$file") {
					$file = "$inc/$file";
					last;
				}
			}
		}
	}
	croak "Target file not found: $file" if ref $file eq '' && ! -f $file;
	$parser->parse_file($file);
	return $parser->{_RESULT};
}

my $SELF = __PACKAGE__->new;

sub __ref
{
	my $ref = shift;
	return if ref $ref->[0];
	croak 'Calling as neither instance method nor class method' unless eval { $ref->[0]->isa(__PACKAGE__) };
	splice @$ref, 0, 1, $SELF;
}

sub string
{
	__ref(\@_);
	my ($self, %args) = @_;
	return join(exists $args{-separator} ? $args{-separator} : '', $self->array(%args));
}

sub array
{
	__ref(\@_);
	my ($self, %args) = @_;
	return @{$self->_extract(%args)};
}

sub arrayref
{
	__ref(\@_);
	my ($self, %args) = @_;
	return [$self->array(%args)];
}

sub hashref
{
	__ref(\@_);
	my ($self, %args) = @_;
	return {$self->array(%args)};
}

sub set_class_default
{
	my ($self, %args) = @_;
	$SELF = __PACKAGE__->new(%args);
}

1;

__END__

=pod

=head1 NAME

Getopt::Config::FromPod - Extract getopt configuration from POD

=head1 VERSION

version v0.0.3

=head1 SYNOPSIS

  # Typical usage for Getopt::Std
  use Getopt::Std;
  use Getopt::Config::FromPod;
  getopts(Getopt::Config::FromPod->string);
  
  =for getopt 'h'
  
  =for getopt 'v'

  # Typical usage for Getopt::Long
  use Getopt::Long;
  use Getopt::Config::FromPod;
  GetOptions(\%opts, Getopt::Config::FromPod->array);
  
  =for getopt 'port|p=i'
  
  =for getopt 'server|s=s'

  # Typical usage for Getopt::Long::Descriptive
  use Getopt::Long::Descriptive;
  use Getopt::Config::FromPod;
  describe_options('my-program %o <some-arg>', Getopt::Config::FromPod->array);
  
  =for getopt [ 'server|s=s', "the server to connect to"                  ]
  
  =for getopt [ 'port|p=i',   "the port to connect to", { default => 79 } ]

  # For most usage, you don't have to construct object or specify parameters but you can do so if necessary
  Getopt::Config::FromPod->new(-tag => 'getopts')->arrayref(-file => $filename);
  Getopt::Config::FromPod->arrayref(-package => $package);
  Getopt::Config::FromPod->string(-separator => ','); # for string() only

=head1 DESCRIPTION

There are many and many C<Getopt::*> modules on CPAN. Is this module yet another option parsing module?

B<NO.>

This module is NOT to be another option parsing module but to be a companion of the modules.

The C<Getopt::*> modules try to solve developers' preference of option parsing.
So, it is likely to be impossible to provide all-in-one option parsing modules.
One of the common problems in option parsing is consistency among:

=over 4

=item 1

Availability in actual process

=item 2

Document shown by, typically, -h option

=item 3

Document shown by perldoc

=back

Some modules such as L<Getopt::Long::Descriptive> solves 1 and 2.
Few modules such as L<Getopt::Auto> solves 1, 2 and 3.
So, if you want to keep all consistencies you need to stick some specific C<Getopt::*> modules.

This module does not stick to specific C<Getopt::*> module and provide a way to specify 1, 2 and 3 in POD.

To tell the truth, this module just collects option specifications distributed in POD.
So, dupulication between POD documentation and specification are NOT eliminated.
However, I believe it has some advantages to enable us to describe documentation and specification at the same place.

Configuration is described as POD section C<getopt> like the follwings:

  =for getopt 'v:'

  =for getopt 'port|p=i'

  =for getopt [ 'port|p=i',   "the port to connect to", { default => 79 } ]

You can also use =begin/=end pair but it is rarely necessary and useful.

  =begin getopt
  [ 'port|p=i',
    "the port to connect to",
    { default => 79 }
  ]
  =end getopt

They are eval'ed so you can describe array references, hash references and so on as above.

=head1 METHODS

All methods except for C<new()> are callable as class methods, also.
In this case, it works as if a shared object is specified as the first argument.

=head2 new(%args)

Constructor. An available parameter is C<'-tag'>.
You can change POD tag name from C<'getopt'>.

  Getopt::Config::FromPod->new(-tag => 'options')->string; # returns 'h'
  =for options 'h'

=head2 string(%args)

Returns a string concatenated parameters written in POD.
Available parameters are as follows. Except for C<'-separator'>, all arguments are available for other accessors.

=over 4

=item *

C<'-separator'> =E<gt> $separator

parameters are concatenated with this separator. Defaults to C<''>, that is empty string.

=item *

C<'-file'> =E<gt> $filename

Read POD from the specified file. If specified, C<'-package'> is ignored.

=item *

C<'-package'> =E<gt> $packagename

Read POD from the file including the specified package. Defaults to C<'main'>.

=back

=head2 array(%args)

Returns an array of parameters written in POD. See C<string> for available parameters.

=head2 arrayref(%args)

Returns an array reference of parameters written in POD. See C<string> for available parameters.

=head2 hashref(%args)

Returns a hash reference of parameters written in POD. See C<string> for available parameters.

=head2 set_class_default(%args)

Change behavior called as class method. All class methods afther this method work as if C<%args> is prepended prior to the original arguments.
This is useful for tests of the case that POD is written in .pl file and code is implemented in .pm file.

  # foo.pm
  use Getopt::Std;
  use Getopt::Config::FromPod;
  getopts(Getopt::Config::FromPod->string);
  
  # foo.pl
  =for getopt 'h'
  
  =for getopt 'v'
  
  # foo.t
  use Getopt::Config::FromPod;
  Getopt::Config::FromPod->set_class_default(-file => 'foo.pl');

=head1 SEE ALSO

=over 4

=item *

L<Getopt::AsDocumented> Another Getopt module to use POD as configuration.

=item *

L<Getopt::Euclid> Yet another Getopt module to use POD as configuration.

=item *

L<Getopt::Auto> Yet yet another Getopt module to use POD as configuration.

=item *

L<Getopt::Long::DescriptivePod> Use another approach to sync with POD and configuration, updating POD from configuration.

=item *

L<Getopt::Compact> When showing POD usage, POD description is munged.

=back

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
