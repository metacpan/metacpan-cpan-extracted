# Copyrights 2007-2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Log-Report-Lexicon. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Log::Report::Lexicon::Index;
use vars '$VERSION';
$VERSION = '1.10';


use warnings;
use strict;

use Log::Report       'log-report-lexicon';
use Log::Report::Util  qw/parse_locale/;
use File::Find         ();

# The next two need extension when other lexicon formats are added
sub _understand_file_format($) { $_[0] =~ qr/\.(?:gmo|mo|po)$/i }

sub _find($$)
{   my ($index, $name) = (shift, lc shift);
    $index->{"$name.mo"} || $index->{"name.gmo"} || $index->{"$name.po"};  # prefer mo
}

# On windows, other locale names are used.  They will get translated
# into the Linux (ISO) convensions.

my $locale_unifier;
if($^O eq 'MSWin32')
{   require Log::Report::Win32Locale;
    Log::Report::Win32Locale->import;
    $locale_unifier = sub { iso_locale($_[0]) };
}
else
{   # some UNIXes do not understand "POSIX"
    $locale_unifier = sub { uc $_[0] eq 'POSIX' ? 'c' : lc $_[0] };
}


sub new($;@)
{   my ($class, $dir) = (shift, shift);
    bless {dir => $dir, @_}, $class;  # dir before first argument.
}

#-------------------

sub directory() {shift->{dir}}

#-------------------

sub index() 
{   my $self = shift;
    return $self->{index} if exists $self->{index};

    my $dir       = $self->directory;
    my $strip_dir = qr!\Q$dir/!;

    $self->{index} = {};
    File::Find::find
    ( +{ wanted   => sub
           { -f && !m[/\.] && _understand_file_format($_) or return 1;
             (my $key = $_) =~ s/$strip_dir//;
             $self->addFile($key, $_);
             1;
           }
       , follow      => 1
       , no_chdir    => 1
       , follow_skip => 2
       } , $dir
    );

    $self->{index};
}


sub addFile($;$)
{   my ($self, $base, $abs) = @_;
    $abs ||= File::Spec->catfile($self->directory, $base);
    $base =~ s!\\!/!g;  # dos->unix
    $self->{index}{lc $base} = $abs;
}


sub find($$)
{   my $self   = shift;
    my $domain = lc shift;
    my $locale = $locale_unifier->(shift);

    my $index = $self->index;
    keys %$index or return undef;

    my ($lang, $terr, $cs, $modif) = parse_locale $locale;
    unless(defined $lang)
    {   defined $locale or $locale = '<undef>';
        # avoid problem with recursion, not translatable!
        print STDERR "illegal locale $locale, when looking for $domain";
        return undef;
    }

    $terr  = defined $terr  ? '_'.$terr  : '';
    $cs    = defined $cs    ? '.'.$cs    : '';
    $modif = defined $modif ? '@'.$modif : '';

    (my $normcs = $cs) =~ s/[^a-z0-9]//g;
    if(length $normcs)
    {   $normcs = "iso$normcs" if $normcs !~ /[^0-9-]/;
        $normcs = '.'.$normcs;
    }

    my $fn;
    for my $f ("/lc_messages/$domain", "/$domain")
    {   $fn
        ||= _find($index, "$lang$terr$cs$modif$f")
        ||  _find($index, "$lang$terr$normcs$modif$f")
        ||  _find($index, "$lang$terr$modif$f")
        ||  _find($index, "$lang$modif$f")
        ||  _find($index, "$lang$f");
    }

    $fn
    || _find($index, "$domain/$lang$terr$cs$modif")
    || _find($index, "$domain/$lang$terr$normcs$modif")
    || _find($index, "$domain/$lang$terr$modif")
    || _find($index, "$domain/$lang$cs$modif")
    || _find($index, "$domain/$lang$normcs$modif")
    || _find($index, "$domain/$lang$modif")
    || _find($index, "$domain/$lang");
}


sub list($;$)
{   my $self   = shift;
    my $domain = lc shift;
    my $filter = shift;
    my $index  = $self->index;
    my @list   = map $index->{$_}, grep m!\b\Q$domain\E\b!, keys %$index;

    defined $filter
        or return @list;

    $filter    = qr/\.\Q$filter\E$/i
        if defined $filter && ref $filter ne 'Regexp';

    grep $_ =~ $filter, @list;
}

#-------------------------------------


1;
