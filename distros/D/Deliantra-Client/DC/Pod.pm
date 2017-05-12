package DC::Pod;

use common::sense;

use Storable;

our $VERSION = 1.03;

our $goto_document = sub { };
our %wiki;

my $MA_BEG = "\x{fcd0}";
my $MA_SEP = "\x{fcd1}";
my $MA_END = "\x{fcd2}";

# nodes (order must stay as it is)
sub N_PARENT (){ 0 }
sub N_PAR    (){ 1 }
sub N_LEVEL  (){ 2 }
sub N_KW     (){ 3 }
sub N_DOC    (){ 4 }

# paragraphs (order must stay as it is)
sub P_INDENT (){ 0 }
sub P_LEVEL  (){ 1 }
sub P_MARKUP (){ 2 }
sub P_INDEX  (){ 3 }

our %wiki;

sub load_docwiki {
   *wiki = Storable::retrieve $_[0];
}

sub goto_document($) {
   $goto_document->(split /\//, $_[0]);
}

sub is_prefix_of($@) {
   my ($node, @path) = @_;

   return 1 unless @path;

   my $kw = pop @path;

   $node = $node->[N_PARENT]
      or return 0;

   return scalar grep $_ eq $kw, @{ $node->[N_KW] };
}

sub find(@) {
   my (@path) = @_;

   return unless @path;

   my $kw = pop @path;

   my %res = map +($_, $_),
                grep { is_prefix_of $_, @path }
                   map @$_,
                      $kw eq "*" ? values %wiki
                                 : $wiki{$kw} || ();

   values %res
}

sub full_path_of($) {
   my ($node) = @_;

   my @path;

   while ($node) {
      unshift @path, $node;
      $node = $node->[N_PARENT];
   }

   @path
}

sub full_path($) {
   join "/", map $_->[N_KW][0], &full_path_of
}

sub section_of($) {
   my ($node) = @_;

   my $doc = $node->[N_DOC];
   my $par = $node->[N_PAR];
   my $lvl = $node->[N_LEVEL];

   my @res;

   do {
      my $p = $doc->[$par];

      if (length $p->[P_MARKUP]) {
         push @res, {
            markup => $p->[P_MARKUP],
            indent => $p->[P_INDENT],
         };
      }
   } while $doc->[++$par][P_LEVEL] > $lvl;

   @res
}

sub section(@) {
   map section_of $_, &find
}

sub thaw_section(\@\%) {
   for (@{$_[0]}) {
      $_->{markup} =~ s{
         $MA_BEG
         ([^$MA_END]+)
         $MA_END
      }{
         my ($type, @arg) = split /$MA_SEP/o, $1;

         $_[1]{$type}($_, @arg)
      }ogex;
   }
}

my %as_common = (
   h1 => sub {
      "\n\n<span foreground='#ffff00' size='x-large'>$_[1]</span>\n"
   },
   h2 => sub {
      "\n\n<span foreground='#ccccff' size='large'>$_[1]</span>\n"
   },
   h3 => sub {
      "\n\n<span size='large'>$_[1]</span>\n"
   },
);

my %as_label = (
   %as_common,
   image => sub {
      my ($par, $path) = @_;

      "<small>img</small>"
   },
   link => sub {
      my ($par, $text, $link) = @_;

      "<span foreground='#ffff00'>↺</span><span foreground='#c0c0ff' underline='single'>" . (DC::asxml $text) . "</span>"
   },
);

sub as_label(@) {
   thaw_section @_, %as_label;

   my $text =
      join "\n",
         map +("\xa0" x ($_->{indent} / 4)) . $_->{markup},
            @_;

   $text =~ s/^\s+//;
   $text =~ s/\s+$//;

   $text
}

my %as_paragraphs = (
   %as_common,
   image => sub {
      my ($par, $path, $flags) = @_;

      push @{ $par->{widget} }, new DC::UI::Image path => $path,
         $flags & 1 ? (max_h => $::FONTSIZE) : ();

      "\x{fffc}"
   },
   link => sub {
      my ($par, $text, $link) = @_;

      push @{ $par->{widget} }, new DC::UI::Label
         markup     => "<span foreground='#ffff00'>↺</span><span foreground='#c0c0ff' underline='single'>" . (DC::asxml $text) . "</span>",
         fontsize   => 0.8,
         can_hover  => 1,
         can_events => 1,
         padding_x  => 0,
         padding_y  => 0,
         tooltip    => "Go to <i>" . (DC::asxml $link) . "</i>",
         on_button_up => sub {
            goto_document $link;
         };

      "\x{fffc}"
   },
);

sub as_paragraphs(@) {
   thaw_section @_, %as_paragraphs;

   @_
}

sub section_paragraphs(@) {
   as_paragraphs &section
}

sub section_label(@) {
   as_label &section
}

1
