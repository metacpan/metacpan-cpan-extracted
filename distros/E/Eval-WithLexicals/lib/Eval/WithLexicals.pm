package Eval::WithLexicals;

use Moo;
use Moo::Role ();
use Sub::Quote;

our $VERSION = '1.003005'; # 1.3.5
$VERSION = eval $VERSION;

has lexicals => (is => 'rw', default => quote_sub q{ {} });

{
  my %valid_contexts = map +($_ => 1), qw(list scalar void);

  has context => (
    is => 'rw', default => quote_sub(q{ 'list' }),
    isa => sub {
      my ($val) = @_;
      die "Invalid context type $val - should be list, scalar or void"
        unless $valid_contexts{$val};
    },
  );
}

has in_package => (
  is => 'rw', default => quote_sub q{ 'Eval::WithLexicals::Scratchpad' }
);

has prelude => (
  is => 'rw', default => quote_sub q{ 'use strictures 1;' }
);

sub with_plugins {
  my($class, @names) = @_;

  Moo::Role->create_class_with_roles($class,
    map "Eval::WithLexicals::With$_", @names);
}

sub setup_code {
  my($self) = @_;
  $self->prelude;
}

sub capture_code {
  ( qq{ BEGIN { Eval::WithLexicals::Util::capture_list() } } )
}

sub eval {
  my ($self, $to_eval) = @_;
  local *Eval::WithLexicals::Cage::current_line;
  local *Eval::WithLexicals::Cage::pad_capture;
  local *Eval::WithLexicals::Cage::grab_captures;

  my $package = $self->in_package;
  my $setup_code = join '', $self->setup_code,
    # $_[2] being what is passed to _eval_do below
    Sub::Quote::capture_unroll('$_[2]', $self->lexicals, 2);

  my $capture_code = join '', $self->capture_code;

  local our $current_code = qq!
${setup_code}
sub Eval::WithLexicals::Cage::current_line {
package ${package};
#line 1 "(eval)"
${to_eval}
;sub Eval::WithLexicals::Cage::pad_capture { }
${capture_code}
sub Eval::WithLexicals::Cage::grab_captures {
  no warnings 'closure'; no strict 'vars';
  package! # hide from PAUSE
    .q! Eval::WithLexicals::VarScope;!;
  # rest is appended by Eval::WithLexicals::Util::capture_list, called
  # during parsing by the BEGIN block from capture_code.

  $self->_eval_do(\$current_code, $self->lexicals, $to_eval);
  $self->_run(\&Eval::WithLexicals::Cage::current_line);
}

sub _run {
  my($self, $code) = @_;

  my @ret;
  my $ctx = $self->context;
  if ($ctx eq 'list') {
    @ret = $code->();
  } elsif ($ctx eq 'scalar') {
    $ret[0] = $code->();
  } else {
    $code->();
  }
  $self->lexicals({
    %{$self->lexicals},
    %{$self->_grab_captures},
  });
  @ret;
}

sub _grab_captures {
  my ($self) = @_;
  my $cap = Eval::WithLexicals::Cage::grab_captures();
  foreach my $key (keys %$cap) {
    my ($sigil, $name) = $key =~ /^(.)(.+)$/;
    my $var_scope_name = $sigil.'Eval::WithLexicals::VarScope::'.$name;
    if ($cap->{$key} eq eval "\\${var_scope_name}") {
      delete $cap->{$key};
    }
  }
  $cap;
}

sub _eval_do {
  my ($self, $text_ref, $lexical, $original) = @_;
  local @INC = (sub {
    if ($_[1] eq '/eval_do') {
      open my $fh, '<', $text_ref;
      $fh;
    } else {
      ();
    }
  }, @INC);
  do '/eval_do' or die $@;
}

{
  package # hide from PAUSE
    Eval::WithLexicals::Util;

  use B qw(svref_2object);

  sub capture_list {
    my $pad_capture = \&Eval::WithLexicals::Cage::pad_capture;
    my @names = grep defined && length && $_ ne '&', map $_->PV, grep $_->can('PV'),
      svref_2object($pad_capture)->OUTSIDE->PADLIST->ARRAYelt(0)->ARRAY;
    $Eval::WithLexicals::current_code .=
      '+{ '.join(', ', map "'$_' => \\$_", @names).' };'
      ."\n}\n}\n1;\n";
  }
}

1;
__END__

=head1 NAME

Eval::WithLexicals - pure perl eval with persistent lexical variables

=head1 SYNOPSIS

  # file: bin/tinyrepl

  #!/usr/bin/env perl

  use strictures 1;
  use Eval::WithLexicals;
  use Term::ReadLine;
  use Data::Dumper;
  use Getopt::Long;

  GetOptions(
    "plugin=s" => \my @plugins
  );

  $SIG{INT} = sub { warn "SIGINT\n" };

  { package Data::Dumper; no strict 'vars';
    $Terse = $Indent = $Useqq = $Deparse = $Sortkeys = 1;
    $Quotekeys = 0;
  }

  my $eval = @plugins
   ? Eval::WithLexicals->with_plugins(@plugins)->new
   : Eval::WithLexicals->new;

  my $read = Term::ReadLine->new('Perl REPL');
  while (1) {
    my $line = $read->readline('re.pl$ ');
    exit unless defined $line;
    my @ret; eval {
      local $SIG{INT} = sub { die "Caught SIGINT" };
      @ret = $eval->eval($line); 1;
    } or @ret = ("Error!", $@);
    print Dumper @ret;
  }

  # shell session:

  $ perl -Ilib bin/tinyrepl 
  re.pl$ my $x = 0;
  0
  re.pl$ ++$x;
  1
  re.pl$ $x + 3;
  4
  re.pl$ ^D
  $

=head1 METHODS

=head2 new

  my $eval = Eval::WithLexicals->new(
    lexicals => { '$x' => \1 },      # default {}
    in_package => 'PackageToEvalIn', # default Eval::WithLexicals::Scratchpad
    context => 'scalar',             # default 'list'
    prelude => 'use warnings',       # default 'use strictures 1'
  );

=head2 eval

  my @return_value = $eval->eval($code_to_eval);

=head2 lexicals

  my $current_lexicals = $eval->lexicals;

  $eval->lexicals(\%new_lexicals);

=head2 in_package

  my $current_package = $eval->in_package;

  $eval->in_package($new_package);

=head2 context

  my $current_context = $eval->context;

  $eval->context($new_context); # 'list', 'scalar' or 'void'

=head2 prelude

Code to run before evaling code. Loads L<strictures> by default.

  my $current_prelude = $eval->prelude;

  $eval->prelude(q{use warnings}); # only warnings, not strict.

=head2 with_plugins

  my $eval = Eval::WithLexicals->with_plugins("HintPersistence")->new;

Construct a class with the given plugins. Plugins are roles located under
a package name like C<Eval::WithLexicals::With*>.

Current plugins are:

=over 4

=item * HintPersistence

When enabled this will persist pragams and other compile hints between evals
(for example the L<strict> and L<warnings> flags in effect). See
L<Eval::WithLexicals::WithHintPersistence> for further details.

=back

=head1 AUTHOR

Matt S. Trout <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

David Leadbeater <dgl@dgl.cx>

haarg - Graham Knop (cpan:HAARG) <haarg@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2010 the Eval::WithLexicals L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
