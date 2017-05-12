package Locale::MakePhrase::BackingStore;
our $VERSION = 0.2;
our $DEBUG = 0;

=head1 NAME

Locale::MakePhrase::BackingStore - base-class of the backing store
functionality.

=head1 DESCRIPTION

This is a base-class, of storage-specific implementations for the
L<Locale::MakePhrase> module.

The backing-store may choose to implement seperate files for each
language, or a single file for all languages.  It may choose to
implement database lookup... and so on.

This base class implements a generic implementation, which can be used
as a starting point. You should also look at Locale::MakePhrase::BackingStore::E<lt>some moduleE<gt>
for more examples.

L<Locale::MakePhrase> implements the following backing stores:

=over 2

=item *

Single file for all languages (see backing store:
L<File|Locale::MakePhrase::BackingStore::File>)

=item *

Files stored within a directory (see backing store:
L<Directory|Locale::MakePhrase::BackingStore::Directory>)

=item *

Generic database table (see backing store:
L<Database|Locale::MakePhrase::BackingStore::Database>)

=item *

PostgreSQL database table (see backing store:
L<Database::PostgreSQL|Locale::MakePhrase::BackingStore::Database::PostgreSQL>)

=back

Alternatively, you could implement an application specific backing
store by doing the following:

=over 3

=item 1.

Make a package which derives from this class.

=item 2.

Implement the init() method, retrieving any options that may have
been supplied to the constructor.

=item 3.

Overload the get_rules() method, returning a list-reference of
L<Locale::MakePhrase::LanguageRule> objects, from the translations
available from your backing store.

=back

For an implementation which uses a text file, this could mean that you
would load the text file if it has changed, constructing the rule
objects during the load, then return a list-reference of objects which
match the request.

For a database implementation, you would need to query the database
for translations which match the request, then construct rule objects
from those translations.

=head1 API

The following methods are implemented:

=cut

{ no warnings; require v5.8.0; }
use strict;
use warnings;
use utf8;
use base qw();
use Locale::MakePhrase::LanguageRule;
use Locale::MakePhrase::Utils qw(die_from_caller);
local $Data::Dumper::Indent = 1 if $DEBUG;

#--------------------------------------------------------------------------

=head2 new()

Construct a backing store instance; arguments are passed to the init()
method.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = bless {}, $class;
  return $self->init(@_);
}

#--------------------------------------------------------------------------

=head2 $self init([...])

Allow sub-class to control construction.  The sub-class must return
itself, so as to make construction succeed.

=cut

sub init { shift }

#--------------------------------------------------------------------------

=head2 \@rule_objs get_rules($context,$key,\@languages)

Returns a list-reference of rule objects which have just been
retrieved from the storage mechanism.  The objects will have been
based on the values of the $context (which is a stringified version of
whatever get passed to C<context_translate> or a value of undef), the
$key (which is your application text string) and the language tags
that L<Locale::MakePhrase> determined for this instance.

Since this is a base class, you need to supply a real implementation,
although you can still use L<Locale::MakePhrase> with this minimal
implementation, so as to allow you to continue application development.

=cut

sub get_rules {
  my ($self,$context,$key,$languages) = @_;
  my $language = shift @{$languages};
  my $rule = new Locale::MakePhrase::LanguageRule(
    language => $language,
    translation => "~[$language~] -> $key",
  );
  my @translations;
  push @translations, $rule;
  print STDERR "Found translations:\n", Dumper(@translations) if $DEBUG;
  return \@translations;
}

#--------------------------------------------------------------------------

=head2 $rule_obj make_rule()

This is a helper routine for making a LanguageRule object. ie: you
would use it like this, within your get_rules() method:

  sub get_rules {
    ...
    my $rule_obj = $self->make_rule(
      key => $key,
      language => $lang,
      expression => $expression,
      priority => $priority,
      translation => $translation,
    );
    ...
  }

Thus, it takes a hash or hash_ref with the options: C<key>,
C<language>, C<expression>, C<priority> and C<translation>

=cut

sub make_rule {
  my $self = shift;
  my %args;

  # allow multiple forms of argument passing
  if (@_ == 1 and ref($_[0] eq 'HASH')) {
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
    die("Invalid arguments passed to make_rule()");
  }

  # Validate arguments
  die_from_caller("Bad rule definition") unless ($args{language} and defined $args{translation});

  # make the rule
  return new Locale::MakePhrase::LanguageRule(%args);
}

1;
__END__
#--------------------------------------------------------------------------

