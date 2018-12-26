package Lingua::Any::Numbers;
$Lingua::Any::Numbers::VERSION = '0.50';
use strict;
use warnings;

use subs qw(
   to_string
   num2str
   number_to_string

   to_ordinal
   num2ord
   number_to_ordinal

   available
   available_langs
   available_languages
);

use constant LCLASS         => 0;
use constant RE_LEGACY_PERL => qr{
   Perl \s+ (.+?) \s+ required
   --this \s+ is \s+ only \s+ (.+?),
   \s+ stopped
}xmsi;
use File::Spec;
use base qw( Exporter );
use Carp qw(croak);

our(@EXPORT, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {
   *num2str         = *number_to_string    = \&to_string;
   *num2ord         = *number_to_ordinal   = \&to_ordinal;
   *available_langs = *available_languages = \&available;

   @EXPORT          = ();
   @EXPORT_OK       = qw(
      to_string  number_to_string  num2str
      to_ordinal number_to_ordinal num2ord
      available  available_langs   available_languages
      language_handler
   );
}

%EXPORT_TAGS = (
   all       => [ @EXPORT_OK ],
   standard  => [ qw/ available           to_string        to_ordinal        / ],
   standard2 => [ qw/ available_languages to_string        to_ordinal        / ],
   long      => [ qw/ available_languages number_to_string number_to_ordinal / ],
);

@EXPORT_TAGS{ qw/ std std2 / } = @EXPORT_TAGS{ qw/ standard standard2 / };

my %LMAP;
my $DEFAULT    = 'EN';
my $USE_LOCALE = 0;
# blacklist non-language modules
my %NOT_LANG   = map { $_ => 1 } qw(
   Any
   Base
   Conlang
   Slavic
);

_probe(); # fetch/examine/compile all available modules

sub import {
   my($class, @args) = @_;
   my @exports;

   foreach my $thing ( @args ) {
      if ( lc $thing eq '+locale' ) { $USE_LOCALE = 1; next; }
      if ( lc $thing eq '-locale' ) { $USE_LOCALE = 0; next; }
      push @exports, $thing;
   }

   return $class->export_to_level( 1, $class, @exports );
}

sub to_string  {
   my @args = @_;
   return _to( string  => @args )
}

sub to_ordinal {
   my @args = @_;
   return _to( ordinal => @args )
}

sub available {
   my @ids = sort keys %LMAP;
   return @ids;
}

sub language_handler {
   my $lang = shift             || return;
   my $h    = $LMAP{ uc $lang } || return;
   return $h->{class};
}

# -- PRIVATE -- #

sub _to {
   my $type   = shift || croak 'No type specified';
   my $n      = shift;
   my $lang   = shift || _get_lang();
      $lang   = uc $lang;
      $lang   = _get_lang($lang) if $lang eq 'LOCALE';
   if ( ($lang eq 'LOCALE' || $USE_LOCALE) && ! exists $LMAP{ $lang } ) {
      _w("Locale language ($lang) is not available. "
        ."Falling back to default language ($DEFAULT)");
      $lang = $DEFAULT; # prevent die()ing from an absent driver
   }
   my $struct = $LMAP{ $lang } || croak "Language ($lang) is not available";
   return $struct->{ $type }->( $n );
}

sub _get_lang {
   my $lang;
   my $locale = shift;
   $lang = _get_lang_from_locale() if $locale || $USE_LOCALE;
   $lang = $DEFAULT if ! $lang;
   return uc $lang;
}

sub _get_lang_from_locale {
   require I18N::LangTags::Detect;
   my @user_wants = I18N::LangTags::Detect::detect();
   my $lang = $user_wants[0] || return;
   ($lang,undef) = split m{\-}xms, $lang; # tr-tr
   return $lang;
}

sub _is_silent { return defined &SILENT && SILENT() }

sub _dummy_ordinal { return shift }
sub _dummy_string  { return shift }
sub _dummy_oo      {
   my $class = shift;
   my $type  = shift;
   return $type && ! $class->can('parse')
         ? sub { $class->new->$type( shift ) }
         : sub { $class->new->parse( shift ) }
         ;
}

sub _probe {
   my @compile;
   foreach my $module ( _probe_inc() ) {
      my $class = $module->[LCLASS];

      (my $inc = $class) =~ s{::}{/}xmsg;
      $inc .= q{.pm};

      if ( ! $INC{ $inc } ) {
         my $file = File::Spec->catfile( split m{::}xms, $class ) . '.pm';
         eval {
            require $file;
            $class->import;
            1;
         } or do {
            # some modules need attention
            _probe_error($@, $class);
            next;
         };
         $INC{ $inc } = $INC{ $file };
      }

      push @compile, $module;
   }
   _compile( \@compile );
   return 1;
}

sub _probe_error {
   my($e, $class) = @_;
   if ( $e =~ RE_LEGACY_PERL ) { # JA -> 5.6.2
      return _w( _eprobe( $class, $1, $2 ) );
   }
   croak("An error occurred while including sub modules: $e");
}

sub _probe_inc {
   require Symbol;
   my @classes;
   foreach my $inc ( @INC ) {
      my $path = File::Spec->catfile( $inc, 'Lingua' );
      next if ! -d $path;
      my $DIRH = Symbol::gensym();
      opendir $DIRH, $path or croak "opendir($path): $!";
      while ( my $dir = readdir $DIRH ) {
         next if $dir =~ m{ \A [.] }xms || $NOT_LANG{ $dir };
         ($dir) = $dir =~ m{([a-z0-9_]+)}xmsi or next; # untaint
         my @rs = _probe_exists($path, $dir);
         next if ! @rs; # bogus
         foreach my $e ( @rs ) {
            my($file, $type) = @{ $e };
            push @classes, [ join(q{::}, 'Lingua', $dir, $type), $file, $dir ];
         }
      }
      closedir $DIRH;
   }

   return @classes;
}

sub _probe_exists {
   my($path, $dir) = @_;
   my @results;
   foreach my $possibility ( qw[ Numbers Num2Word Nums2Words Numeros Nums2Ords ] ) {
      my $file = File::Spec->catfile( $path, $dir, $possibility . '.pm' );
      next if ! -e $file || -d _;
      push @results, [ $file, $possibility ];
   }
   return @results;
}

sub _w {
   return _is_silent() ? 1 : do { warn "@_\n"; 1 };
}

sub _eprobe {
   my @args = @_;
   my $tmp  = @args > 2 ? q{%s requires a newer (%s) perl binary. You have %s}
            :             q{%s requires a newer perl binary. You have %s}
            ;
   return sprintf $tmp, @args;
}

sub _merge_into_numbers {
   my($id, $lang ) = @_;
   my $e       = delete $lang->{ $id };
   my %test    = map { @{ $_ } } @{ $e };
   my $words   = delete $test{'Lingua::' . $id . '::Nums2Words' };
   my $ords    = delete $test{'Lingua::' . $id . '::Nums2Ords' };
   my $numbers = delete $test{'Lingua::' . $id . '::Numbers' };

   if ( ! $numbers && ( $ords || $words ) ) {
      my $file  = sprintf 'Lingua/%s/Numbers.pm', $id;
      my $c     = sprintf 'Lingua::%s::Numbers', $id;
      $INC{ $file } ||= 'Fake placeholder module';
      my $n     = $c . '::num2' . lc $id;
      my $v     = $c . '::VERSION';
      my $o     = $n . '_ordinal';
      my $f     = $c . '::_faked_by_lingua_any_numbers';
      my $card  = 'Lingua::' . $id . '::Nums2Words::num2word';
      my $ord   = 'Lingua::' . $id . '::Nums2Ords::num2ord';
      $lang->{ $id } = [ $c, $INC{ $file } ];

      no strict qw( refs ); ## no critic (ProhibitProlongedStrictureOverride)
      *{ $n } =   \&{ $card    } if $words && ! $c->can('num2tr');
      *{ $o } =   \&{ $ord     } if $ords  && ! $c->can('num2ord');
      *{ $v } = sub { __PACKAGE__->VERSION } if ! $c->can('VERSION');
      *{ $f } = sub { return { words => $words, ords => $ords } };

      return;
   }

   $lang->{ $id } = $e; # restore

   return;
}

sub _compile {
   my $classes = shift;
   my %lang;
   foreach my $e ( @{ $classes } ) {
      my($class, $file, $id) = @{ $e };
      $lang{ $id } = [] if ! defined $lang{ $id };
      push @{ $lang{ $id } }, [ $class, $file ];
   }

   foreach my $id ( keys %lang ) {
      if ( $id eq 'PT' ) {
         _merge_into_numbers( $id, \%lang );
         next;
      }
      my @choices = @{ $lang{ $id } };
      my $numbers;
      foreach my $c ( @choices ) {
         my($class, $file) = @{ $c };
         $numbers = $c if $class =~ m{::Numbers\z}xms;
      }
      $lang{ $id } = $numbers ? [ @{ $numbers} ] : shift @choices;
   }

   foreach my $l ( keys %lang ) {
      my $e = $lang{ $l };
      my $c = $e->[0];
      $LMAP{ uc $l } = {
         string  => _test_cardinal($c, $l),
         ordinal => _test_ordinal( $c, $l),
         class   => $c,
      };
   }

   return;
}

sub _test_cardinal {
   my($c, $l) = @_;
   $l = lc $l;
   no strict qw(refs);
   my %s = %{ "${c}::" };
   my $n = $s{new};
   return
        $s{"num2${l}"}         ? \&{"${c}::num2${l}"          }
      : $s{"number_to_${l}"}   ? \&{"${c}::number_to_${l}"    }
      : $s{'nums2words'}       ? \&{"${c}::nums2words"        }
      : $s{'num2word'}         ? \&{"${c}::num2word"          }
      : $s{cardinal2alpha}     ? \&{"${c}::cardinal2alpha"    }
      : $s{cardinal} && $n     ? _dummy_oo( $c, 'cardinal' )
      : $s{parse}              ? _dummy_oo( $c )
      : $s{"num2${l}_cardinal"}? $n ? _dummy_oo( $c, "num2${l}_cardinal" )
                                    :       \&{"${c}::num2${l}_cardinal" }
      :                          \&_dummy_string
      ;
}

sub _test_ordinal {
   my($c, $l) = @_;
   $l = lc $l;
   no strict qw(refs);
   my %s = %{ "${c}::" };
   my $n = $s{new} && ! _like_en( $c );
   return
     $s{"ordinate_to_${l}"}   ? \&{"${c}::ordinate_to_${l}"}
   : $s{ordinal2alpha}        ? \&{"${c}::ordinal2alpha"   }
   : $s{ordinal} && $n        ? _dummy_oo( $c, 'ordinal' )
   : $s{"num2${l}_ordinal"}   ? $n ? _dummy_oo( $c, "num2${l}_ordinal" )
                                   :      \&{ "${c}::num2${l}_ordinal" }
   :                          \&_dummy_ordinal
   ;
}

sub _like_en {
   my $c  = shift;
   my $rv = $c->isa('Lingua::EN::Numbers')
            || $c->isa('Lingua::JA::Numbers')
            || $c->isa('Lingua::TR::Numbers')
            ;
   return $rv;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Any::Numbers

=head1 VERSION

version 0.50

=head1 SYNOPSIS

   use Lingua::Any::Numbers qw(:std);
   printf "Available languages are: %s\n", join( ", ", available );
   printf "%s\n", to_string(  45 );
   printf "%s\n", to_ordinal( 45 );

or test all available languages

   use Lingua::Any::Numbers qw(:std);
   foreach my $lang ( available ) {
      printf "%s\n", to_string(  45, $lang );
      printf "%s\n", to_ordinal( 45, $lang );
   }

=head1 DESCRIPTION

The most popular C<Lingua> modules are seem to be the ones that convert
numbers into words. These kind of modules exist for a lot of languages.
However, there is no standard interface defined for them. Most
of the modules' interfaces are completely different and some do not implement
the ordinal conversion at all. C<Lingua::Any::Numbers> tries to create a common
interface to call these different modules. And if a module has a known
interface, but does not implement the required function/method then the
number itself is returned instead of dying. It is also possible to
take advantage of the automatic locale detection if you install all the
supported modules listed in the L</SEE ALSO> section.

L<Task::Lingua::Any::Numbers> can be installed to get all the available modules
related to L<Lingua::Any::Numbers> on C<CPAN>.

=head1 NAME

Lingua::Any::Numbers - Converts numbers into (any available language) string.

=head1 IMPORT PARAMETERS

All functions and aliases can be imported individually, 
but there are some predefined import tags:

   :all        Import everything (including aliases)
   :standard   available(), to_string(), to_ordinal().
   :std        Alias to :standard
   :standard2  available_languages(), to_string(), to_ordinal()
   :std2       Alias to :standard2
   :long       available_languages(), number_to_string(), number_to_ordinal()

=head1 C<IMPORT PRAGMAS>

Some parameters enable/disable module features. C<+> is prefixed to enable
these options. C<Pragmas> have global effect (i.e.: not lexical), they can not
be disabled afterwards.

=head2 locale

Use the language from system locale:

   use Lingua::Any::Numbers qw(:std +locale);
   print to_string(81); # will use locale

However, the second parameter to the functions take precedence. If the language
parameter is used, C<locale> C<pragma> will be discarded.

Install all the C<Lingua::*::Numbers> modules to take advantage of the
locale C<pragma>.

It is also possible to enable C<locale> usage through the functions.
See L</FUNCTIONS>.

C<locale> is implemented with L<I18N::LangTags::Detect>.

=head1 FUNCTIONS

All language parameters (C<LANG>) have a default value: C<EN>. If it is set to
C<LOCALE>, then the language from the system C<locale> will be used
(if available).

=head2 to_string NUMBER [, LANG ]

Aliases:

=over 4

=item C<num2str>

=item number_to_string

=back

=head2 to_ordinal NUMBER [, LANG ]

Aliases: 

=over 4

=item C<num2ord>

=item number_to_ordinal

=back

=head2 available

Returns a list of available language ids.

Aliases:

=over 4

=item available_langs

=item available_languages

=back

=head2 language_handler

Returns the name of the language handler class if you pass a language id and
a class for that language id is loaded. Returns C<undef> otherwise.

This function can not be imported. Use a fully qualified name to call:

   my $sv = language_handler('SV');

=head1 DEBUGGING

=head2 SILENT

If you define a sub named C<Lingua::Any::Numbers::SILENT> and return
a true value from that, then the module will not generate any warnings
when it faces some recoverable errors.

C<Lingua::Any::Numbers::SILENT> is not defined by default.

=head1 CAVEATS

=over 4

=item *

Some modules return C<UTF8>, while others return arbitrary C<encodings>.
C<ascii> is all right, but others will be problematic. A future release can
convert all to C<UTF8>.

=item *

All available modules will immediately be searched and loaded into
memory (before using any function).

=item *

No language module (except C<Lingua::EN::Numbers>) is required by 
L<Lingua::Any::Numbers>, so you'll need to install the other 
modules manually.

=back

=head1 SEE ALSO

   Lingua::AF::Numbers
   Lingua::BG::Numbers
   Lingua::EN::Numbers
   Lingua::EU::Numbers
   Lingua::FR::Numbers
   Lingua::HU::Numbers
   Lingua::IT::Numbers
   Lingua::JA::Numbers
   Lingua::NL::Numbers
   Lingua::PL::Numbers
   Lingua::SV::Numbers
   Lingua::TR::Numbers
   Lingua::ZH::Numbers
   
   Lingua::CS::Num2Word
   Lingua::DE::Num2Word
   Lingua::ES::Numeros
   Lingua::ID::Nums2Words
   Lingua::NO::Num2Word
   Lingua::PT::Nums2Word

You can just install L<Task::Lingua::Any::Numbers> to get all modules above.

=head2 BOGUS MODULES

Some modules on C<CPAN> suggest to convert numbers into words by their
names, but they do something different instead. Here is a list of
the bogus modules:

   Lingua::FA::Number

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
