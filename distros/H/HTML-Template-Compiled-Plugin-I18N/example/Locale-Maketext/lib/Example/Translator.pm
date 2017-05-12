package Example::Translator;

use strict;
use warnings;

our $VERSION = 0;

use Carp qw(croak);

# in mod_perl environment use Apache::Singleton::Request
use parent qw(Class::Singleton);

use Example::I18N;
use HTML::Template::Compiled::Plugin::I18N;

my %lh_of; # cache for the language handles

sub new {
    my ($class, @more) = @_;

    return $class->instance(@more);
}

sub set_language {
    my ($class, $language) = @_;

    $class->new()->{language} = $language;

    return $class;
}

sub get_language {
    my $class = shift;

    my $language = $class->new()->{language}
        or croak 'No language set';

    return $language;
}

sub get_lh {
    my $class = shift;

    my $language = __PACKAGE__->new()->get_language()
        or croak 'Language not set';
    exists $lh_of{$language}
        and return $lh_of{$language};

    # create a language handle for language
    my $lh = Example::I18N->get_handle($language)
        or croak 'What language';

    $lh_of{$language} = $lh;

    return $lh;
}

sub translate {
    my ($class, $arg_ref) = @_;

    my $lh = __PACKAGE__->new()->get_lh();

    my $translation =  $lh->maketext(
        $arg_ref->{text},
        (
            exists $arg_ref->{maketext}
            ? @{ $arg_ref->{maketext} }
            : ()
        ),
    );
    if ( exists $arg_ref->{escape} ) {
        $translation = HTML::Template::Compiled::Plugin::I18N->escape(
            $translation,
            $arg_ref->{escape},
        );
    }
    if ( exists $arg_ref->{formatter} ) {
        my $formatter_ref = $arg_ref->{formatter};
        for my $formatter ( @{$formatter_ref} ) {
            # Call here a formatter like Markdown
            if (lc $formatter eq lc 'Markdown') {
                # $translation = ... $tanslation;
            }
        }
    }
    if ( exists $arg_ref->{unescaped} ) {
        $translation = HTML::Template::Compiled::Plugin::I18N->expand_unescaped(
            $translation,
            $arg_ref->{unescaped},
        );
    }

    return $translation;
}

1;

__END__

$Id: Translator.pm 163 2009-12-03 09:20:38Z steffenw $