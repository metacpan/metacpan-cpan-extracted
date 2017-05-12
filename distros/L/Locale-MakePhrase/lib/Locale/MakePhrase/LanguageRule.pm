package Locale::MakePhrase::LanguageRule;
our $VERSION = 0.2;
our $DEBUG = 0;

=head1 NAME

Locale::MakePhrase::LanguageRule - rule instance for a given translation.

=head1 DESCRIPTION

This is a container for the currently translated phrase.  Its main
purpose is to validate the translation rule so that L<Locale::MakePhrase>
doesn't need to do it.

When implementing custom backing stores, you will need to construct
these per translation that can be returned.

=head1 API

The following methods are available:

=cut

use strict;
use warnings;
use utf8;
use Data::Dumper;
use base qw();
use Locale::MakePhrase::Utils qw(die_from_caller);
local $Data::Dumper::Indent = 1 if $DEBUG;

#--------------------------------------------------------------------------

=head2 new()

Construct an instance of the language rule.  Takes a hash or hashref
with the following options:

=over 2

=item C<key>

The input phrase used to generate this translation.  (The backing store
uses it as a search criteria, hence the name 'key'.)

=item C<language>

The language tag that is associated with this specific translation.

Since L<Locale::MakePhrase> will ask the backing store for all
possible translations of a phrase based on the language tags that it
resolved during construction, the translation specific language tag
is stored with the actual translation.

=item C<expression>

The rule expression that will be evaluated when program arguments are
supplied when trying to translate a phrase.

=item C<priority>

When figuring out which rule to apply, L<Locale::MakePhrase::RuleManager>
will sort the rules so that the highest priority rules get evaluated
first.

=item C<translation>

This the text that will be output; it can contain placeholders for
program argument substitution.

=back

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = bless {}, $class;

  # allow either classic style argument passing, or hash-style argument passing
  my %args;
  if (@_ == 1 and ref($_[0]) eq 'HASH') {
    %args = %{$_[0]};
  } elsif (@_ > 1 and not(@_ % 2)) {
    %args = @_;
  } elsif (@_ == 5) {
    $args{key} = shift;
    $args{language} = shift;
    $args{expression} = shift;
    $args{priority} = shift;
    $args{translation} = shift;
  } else {
    die_from_caller("Invalid arguments passed to new()");
  }
  print STDERR "Arguments to ". $class .": ". Dumper(\%args) if $DEBUG > 5;
  $self->{key} = $args{key};
  $self->{language} = $args{language};
  $self->{expression} = $args{expression};
  $self->{priority} = $args{priority};
  $self->{translation} = $args{translation};

  # validate this rule to make sure that it can be used
  $self->{key} = $self->{translation} unless $self->{key};
  die_from_caller("Missing language for this rule") unless $self->{language};
  $self->{expression} = "" unless $self->{expression};
  $self->{priority} = 0 unless $self->{priority};
  die_from_caller("Missing translation for this rule") unless (defined $self->{translation});

  # lc and change - to _
  $self->{language} =~ tr<-A-Z><_a-z>;

  return $self;
}

#--------------------------------------------------------------------------
# Accessor methods

=head2 $string key()

Returns the phrase used as the key for translation lookup.

=cut

sub key { shift->{key} }

=head2 $string language()

Returns the language tag for this translated text.

=cut

sub language { shift->{language} }

=head2 $string expression()

Returns the expression that will be evaluated for this phrase.

=cut

sub expression { shift->{expression} }

=head2 $integer priority()

Return the priority of this phrase.

=cut

sub priority { shift->{priority} }

=head2 $string translation()

Returns the output phrase that matches the input key, for the given
language.

=cut

sub translation { shift->{translation} }

1;
__END__
#--------------------------------------------------------------------------

=head1 SUB-CLASSING

You shouldn't need to sub-class this module, as it is simply used
as a container.

=cut

