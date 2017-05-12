=head1 NAME

MetaTrans::Base - Abstract base class for creating meta-translator plug-ins

=head1 SYNOPSIS

    # This is not a working example. It serves for illustration only.
    # For a working one see MetaTrans::UltralinguaNet source code.

    package MetaTrans::MyPlugin;

    use MetaTrans::Base;
    use vars qw(@ISA);
    @ISA = qw(MetaTrans::Base);

    use HTTP::Request;
    use URI::Escape;

    sub new
    {
        my $class   = shift;
        my %options = @_;

        $options{host_server} = "www.some-online-translator.com"
            unless (defined $options{host_server});

        my $self = new MetaTrans::Base(%options);
        $self = bless $self, $class;

        # supported translation directions:
        #   English <-> German
        #   English <-> French
        #   English <-> Spanish

        $self->set_languages('eng', 'ger', 'fre', 'spa');

        $self->set_dir_1_to_all('eng');
        $self->set_dir_all_to_1('eng');

        return $self;
    }

    sub create_request
    {
        my $self           = shift;
        my $expression     = shift;
        my $src_lang_code  = shift;
        my $dest_lang_code = shift;

        # our-language-codes-to-server-language-codes conversion table
        my %table = (eng => 'eng', ger => 'deu', fre => 'fra', spa => 'esp');

        return new HTTP::Request('GET',
            'http://www.some-online-translator.com/translate.cgi?' .
            'expr=' . uri_escape($expression) . '&' .
            'src='  . $table{$src_lang_code}  . '&' .
            'dst='  . $table{$dest_lang_code}
        );
    }

    sub process_response
    {
        my $self           = shift;
        my $contents       = shift;

        # we don't care about these here, but 
        # in some cases we might need to care
        my $src_lang_code  = shift;
        my $dest_lang_code = shift;

        my @result;
        while ($contents =~ m|
            <td class="expr">([^<]*)</td>
            <td class="trns">([^<]*)</td>
        |gsix)
        {
            my $expression  = $1;
            my $translation = $2;

            # add some $expression and $translation normalization code here

            push @result, ($expression, $translation);
        }
        
        return @result;
    }

    1;

=head1 DESCRIPTION

This class serves as a base for creating C<MetaTrans> plug-ins,
especially those ones, which extract data from online translators.
Please see L<MetaTrans> first. C<MetaTrans::Base> already contains
many features a C<MetaTrans> plug-in must have and makes creating
new plug-ins really easy.

To perform a translation using an online translator (e.g. 
L<http://www.ultralingua.net/>) one needs to do two things:

=over 4

=item 1. Emulate sending a form.

=item 2. Process the HTML output webserver sends in response.

=back

To create a C<MetaTrans> plug-in using C<MetaTrans::Base> one
only needs to do a bit more. The first step is to derrive
from C<MetaTrans::Base> and "override" following two abstract
methods:

=over 4

=item $plugin->create_request($expression, $src_lang_code, $dest_lang_code)

Should return a C<HTTP::Request> object to be used by C<LWP::UserAgent>
for retrieving HTML output, which contains translation of $expression from
the language with $src_lang_code to the language with $dest_lang_code.
This basicaly emulates sending a form.

=item $plugin->process_response($contents, $src_lang_code, $dest_lang_code)

This method should extract translations from the HTML code ($contents)
returned by webserver in response to the request. The translations must
be returned in an array of following form:

    (expression_1, translation_1, expression_2, translation_2, ...)

B<Character encoding must be UTF-8!>
In addition all expressions and their translations should be normalized
in a way so that all the grammar and meaning information were in parenthesis
or behind a semi-colon. For example, if you request a English to French
translation of "dog" from the L<http://www.ultralingua.net/> translator,
the first line of the result is

    dog n. : 1. chien n.m.,f. chienne 2. pitou n.m. (Familier) (Québécisme)

The C<MetaTrans::UltralinguaNet> module returns it as

    ('dog (n.)', 'chien (n.m.,f.)', 'dog (n.)', 'pitou (n.m.)')

=back

The next step is specifying list of languages supported by the plug-in.
We have to say, which languages we are able to translate from and which to.
This can be done easily by calling appropriate methods inherrited from
C<MetaTrans::Base>. Please see L<SPECIFYING SUPPORTED LANGUAGES>.

The last step is setting the C<host_server> attribute to the name of the
online translator used by the plug-in. See L<ATTRIBUTES>.

The C<MetaTrans::UltralinguaNet> source code should serve as a good example
on how to create a C<MetaTrans> plug-in derrived from C<MetaTrans::Base>.

=cut

package MetaTrans::Base;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS %ENV);
use Exporter;
use MetaTrans::Languages qw(get_lang_by_code is_known_lang);

use Carp;
use Encode;
use Getopt::Long;
use HTML::Entities;
use LWP::UserAgent;
use HTTP::Response;

$VERSION     = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%02d", @r };
@ISA         = qw(Exporter);
@EXPORT_OK   = qw(is_exact_match is_match_at_start is_match_expr is_match_words
    convert_to_utf8 M_EXACT M_START M_EXPR M_WORDS M_ALL);
%EXPORT_TAGS = (
    match_consts => [qw(M_EXACT M_START M_EXPR M_WORDS M_ALL)],
    match_funcs  => [qw(is_exact_match is_match_at_start is_match_expr
        is_match_words)],
);


# Expression matching types
use constant M_EXACT => 1; # exact match
use constant M_START => 2; # match at start
use constant M_EXPR  => 3; # match expression
use constant M_WORDS => 4; # match words
use constant M_ALL   => 5; # match anything to anything

=head1 CONSTRUCTOR METHODS

=over 4

=item MetaTrans::Base->new(%options)

This method constructs a new MetaTrans::Base object and returns it. Key/value
pair arguments may be provided to set up the initial state. The following
options correspond to attribute methods described below:

   KEY                  DEFAULT
   ---------------      ----------------    
   host_server          'unknown.server'
   script_name          undef
   timeout              5
   matching             M_START
   match_at_bounds      1

Please note that as long as the C<MetaTrans::Base> is an abstract class,
calling the constructor method only makes sense in the derrived classes.

=cut

sub new
{
    my $class   = shift;
    my %options = @_;

    my $self = bless {}, $class;

    my %defaults = (
        host_server     => 'unknown.server',
        script_name     => undef,
        timeout         => 5,
        matching        => M_START,
        match_at_bounds => 1,
    );

    foreach my $attr (keys %defaults)
    {
        $self->{$attr} = $options{$attr} || $defaults{$attr};
    }

    return $self;
}

=back

=cut


=head1 ATTRIBUTES

=over 4

=item $plugin->host_server

=item $plugin->host_server($name)

Get/set the name of the online translator used by the plug-in. Is is only
used to inform the user where the translation comes from and hence can
be set to any meaningful value. It is a convention to set this to
the online translator base URL with the C<'http://'> stripped. For example, 
the C<MetaTrans::UltralinguaNet> sets C<host_server> to
C<'www.ultralingua.net'>.

=item $plugin->script_name

=item $plugin->script_name($name)

Get/set the name of the script, which runs this plug-in as a command line
application. The script uses this to identify itself when printing usage.
If unset, the script name is extracted from C<$0> variable. See the C<run>
method.

=item $plugin->timeout

=item $plugin->timeout($secs)

Get/set the time in seconds we want to wait for a reply from the online
translator before timing out.

=item $plugin->matching

=item $plugin->matching($type)

Get/set the way of matching the found translations to the searched expression.
Some online translators in addition to the translation of the searched
expression also return translations of related expressions. For example,
we want to translate "dog" from English to French and we also get
translations of "dog days" or "every dog has his day". If this is not what
we want we can help ourselves by setting C<matching> to appropriate value:

=over 8

=item MetaTrans::Base::M_EXACT

Match only those expressions which are the same as the searched one.
Matching is incasesensitive and ignores grammar information, i.e.
everything in parenthesis or after semi-colon. The same applies bellow.

Examples:

    'Dog'  matches        'dog'      (incasesensitive)
    'Hund' matches        'Hund; r'  (grammar information ignored)
    'dog'  does not match 'dog bite' (not an exact match)

=item MetaTrans::Base::M_START

Match those expressions which are prefixed with the searched expression.

Examples:

    'Dog'  matches        'dog bite'      (incasesensitive)
    'Hund' matches        'Hund is los'
    'Hund' does not match 'bissiger Hund' ('Hund' is not a prefix)

=item MetaTrans::Base::M_EXPR

Match those expressions which contain the searched expression, no matter
where.

Examples:

    'Big Dog' matches        'very big dog'
    'big dog' does not match 'big angry dog' ('big dog' is not a substring)

=item MetaTrans::Base::M_WORDS

Match those expressions which contain all the words of the searched
expression.

Examples:

    'big dog' matches        'big angry dog'
    'big dog' does not match 'angry dog'     (not all words are contained)

=item MetaTrans::Base::M_ALL

Return all without any filtering.

=back

You can

    use MetaTrans::Base qw(:match_consts);

to import matching constant names (C<M_EXACT>, C<M_START>, ...) into your
program's namespace.

=item $plugin->match_at_bounds

=item $plugin->match_at_bounds($bool)

Get/set the match-at-boundaries flag. Setting it to true value makes
matching behave in a slightly different way.
Subexpressions and words are matched at word boundaries only. In practice
this means that with C<matching> set to C<M_WORDS> the
expression "big dog"
won't be matched to "big angry doggie" while it would be with
match-at-boundaries set to false value. The same applies to
C<M_START> and C<M_EXPR>. The option has no effect when C<matching> is set
to C<M_EXACT> or C<M_ALL>.

=item $plugin->default_dir

=item $plugin->default_dir($src_lang_code, $dest_lang_code)

Get/set the default translation direction. May only be set to supported one,
see L<SPECIFYING SUPPORTED LANGUAGES>. Returns old value as an array of
two language codes.

=back

=cut

sub host_server     { shift->_elem('host_server',     @_); }
sub script_name     { shift->_elem('script_name',     @_); }
sub timeout         { shift->_elem('timeout',         @_); }
sub match_at_bounds { shift->_elem('match_at_bounds', @_); }

sub matching
{
    my $self = shift;
    my $type = shift;

    my %ok = (M_EXACT, 1, M_START, 1, M_EXPR, 1, M_WORDS, 1, M_ALL, 1);
    my $old = $self->{matching};

    if (defined $type)
    {
        exists $ok{$type} ?
            $self->{matching} = $type :
            carp "invalid matching type: '$type'";
    }

    return $old;
}

sub default_dir
{
    my $self           = shift;
    my $src_lang_code  = shift;
    my $dest_lang_code = shift;

    my @old_direction;
    if (defined @{$self->{direction}} &&
        $self->is_supported_dir(@{$self->{direction}}))
    {
        @old_direction = @{$self->{direction}};
    }
    else
    {
        # return `the first' supported translation direction
        OUTER: foreach my $src_lang_code (@{$self->{language_keys}})
        {
            foreach my $dest_lang_code (@{$self->{language_keys}})
            {
                if ($self->is_supported_dir($src_lang_code, $dest_lang_code))
                {
                    @old_direction = ($src_lang_code, $dest_lang_code);
                    last OUTER;
                }
            }
        }
    }

    return @old_direction
        unless defined $src_lang_code && defined $dest_lang_code;

    if ($self->is_supported_dir($src_lang_code, $dest_lang_code))
    {
        carp "not supported direction: '${src_lang_code}2${dest_lang_code}'";
        return @old_direction;
    }

    @{$self->{direction}} = ($src_lang_code, $dest_lang_code);
    return @old_direction;
}

=head1 SPECIFYING SUPPORTED LANGUAGES

Every C<MetaTrans> plug-in has to specify supported languages and translation
directions. C<MetaTrans::Base> provides several methods for doing so. The
first step is specifying list of all languages, which appear on the left or
right side of any of supported translation directions. Consider your plug-in
supports following ones:

    English -> French
    English -> German
    French  -> Spanish

Then the list of supported languages is simply English, French, German and
Spanish.

The arguments passed to particular methods need to be language codes, not
language names. Please see L<MetaTrans::Languagues> for a complete list.

=over 4

=item $plugin->set_languages(@language_codes)

Set supported languages to the ones specified by C<@language_codes>. In the
above exapmle one would call:

    $plugin->set_languages('eng', 'fre', 'ger', 'spa');

=cut

sub set_languages
{
    my $self           = shift;
    my @language_codes = @_;

    foreach (@language_codes)
    {
        unless (is_known_lang($_))
        {
            carp "unknown language code: '$_', ignoring it";
            next;
        }

        ${$self->{languages}}{$_} = get_lang_by_code($_);
        push @{$self->{language_keys}}, $_; # to keep ordering
    }
}

=item $plugin->set_dir_1_to_1($src_lang_code, $dest_lang_code)

Add support for translating from language with C<$src_lang_code> to language
with C<$dest_lang_code>. Both languages need to be previously declared as
supported.  The method returns true value on success, false value on error. To
specify we support directions from the above example we would simply call:

    $plugin->set_dir_1_to_1('eng', 'fre');
    $plugin->set_dir_1_to_1('eng', 'ger');
    $plugin->set_dir_1_to_1('fre', 'spa');

=cut

sub set_dir_1_to_1
{
    my $self           = shift;
    my $src_lang_code  = shift;
    my $dest_lang_code = shift;

    unless (${$self->{languages}}{$src_lang_code})
    {
        carp "language '$src_lang_code' not supported, " .
            "not setting '${src_lang_code}2${dest_lang_code}'";
        return 0;
    }

    unless (${$self->{languages}}{$dest_lang_code})
    {
        carp "language '$dest_lang_code' not supported, " .
            "not setting '${src_lang_code}2${dest_lang_code}'";
        return 0;
    }

    ${$self->{directions}}{$src_lang_code . "2" . $dest_lang_code} = 1;
    return 1;
}

=item $plugin->unset_dir_1_to_1($src_lang_code, $dest_lang_code)

Remove support for translating from language with C<$src_lang_code> to language
with C<$dest_lang_code>. Both languages need to be previously declared as
supported.  The method returns true value on success, false value on error.

=cut

sub unset_dir_1_to_1
{
    my $self           = shift;
    my $src_lang_code  = shift;
    my $dest_lang_code = shift;

    unless (${$self->{languages}}{$src_lang_code})
    {
        carp "language '$src_lang_code' not supported, " .
            "not unsetting '${src_lang_code}2${dest_lang_code}'";
        return 0;
    }

    unless (${$self->{languages}}{$dest_lang_code})
    {
        carp "language '$dest_lang_code' not supported, " .
            "not unsetting '${src_lang_code}2${dest_lang_code}'";
        return 0;
    }

    undef ${$self->{directions}}{$src_lang_code . "2" . $dest_lang_code};
    return 1;
}

=item $plugin->set_dir_1_to_spec($src_lang_code, @dest_lang_codes)

Add support for translating from language with C<$src_lang_code> to all
languages whichs codes are in C<@dest_lang_codes>. The direction from
C<$src_lang_code> language to itself won't be set as supported even if
C<$src_lang_code> is specified in C<@dest_lang_codes>. However, calling

    $plugin->set_dir_1_to_1($src_lang_code, $src_lang_code);

will do the job if this is what you want. It only results in warning messages
if some of the C<@dest_lang_codes> are unsupported. Only the supported ones
will be used, others are ignored. The method returns number of directions
set as supported on (partial) success, 0 on error.

Example:

    my @all_languages = ('eng', 'fre', 'ger', 'spa');
    $plugin->set_languages(@all_languages);
    $plugin->set_dir_1_to_spec('eng', @all_languages);

... will result in following supported translation directions:

    English -> French
    English -> German
    English -> Spanish

=cut

sub set_dir_1_to_spec
{
    my $self             = shift;
    my $src_lang_code    = shift;
    my @dest_lang_codes  = @_;
    my $set              = 0;

    unless (${$self->{languages}}{$src_lang_code})
    {
        carp "language '$src_lang_code' not supported";
        return $set;
    }

    foreach my $dest_lang_code (@dest_lang_codes)
    {
        next if $dest_lang_code eq $src_lang_code;
        $set += $self->set_dir_1_to_1($src_lang_code, $dest_lang_code);
    }

    return $set;
}

=item $plugin->set_dir_1_to_all($src_lang_code)

This is just a shorter way for writting:

    $plugin->set_dir_1_to_spec($src_lang_code, @all_codes);

where C<@all_codes> is an array of codes of all supported languages.

=cut

sub set_dir_1_to_all
{
    my $self          = shift;
    my $src_lang_code = shift;

    return $self->set_dir_1_to_spec($src_lang_code, @{$self->{language_keys}});
}


=item $plugin->set_dir_spec_to_1($dest_lang_code, @src_lang_codes)

This works exactly as C<set_dir_1_to_spec> with reversed sides.

=cut

sub set_dir_spec_to_1
{
    my $self           = shift;
    my $dest_lang_code = shift;
    my @src_lang_codes = @_;
    my $set            = 0;

    unless (${$self->{languages}}{$dest_lang_code})
    {
        carp "language '$dest_lang_code' not supported";
        return $set;
    }

    foreach my $src_lang_code (@src_lang_codes)
    {
        next if $src_lang_code eq $dest_lang_code;
        $set += $self->set_dir_1_to_1($src_lang_code, $dest_lang_code);
    }

    return $set;
}

=item $plugin->set_dir_all_to_1($dest_lang_code)

This is just a shorter way for writting:

    $plugin->set_dir_spec_to_1($dest_lang_code, @all_codes);

where C<@all_codes> is an array of codes of all supported languages.
Example:

    my @src_lang_codes = ('ger', 'fre', 'spa');
    $plugin->set_languages('eng', 'por', @src_lang_codes);
    $plugin->set_dir_spec_to_1('eng', @src_lang_codes);

... will result in following supported translation directions:

    German  -> English
    French  -> English
    Spanish -> English

But if we replaced the last line with

    $plugin->set_dir_all_to_1('eng');

the result would have been:

    Portuguese -> English
    German     -> English
    French     -> English
    Spanish    -> English

=cut

sub set_dir_all_to_1
{
    my $self           = shift;
    my $dest_lang_code = shift;

    return $self->set_dir_spec_to_1($dest_lang_code,
        @{$self->{language_keys}});
}

=back

=cut

=head1 PLUG-IN REQUIRED METHODS

These are the methods C<MetaTrans> expects every plug-in to provide. You only
need to worry about this if you are writting a plug-in from a scratch. If you
are derriving from C<MetaTrans::Base> all these methods are inherited. They
make use of the abstract methods C<create_request> and C<process_response>,
attribute values and supported translation directions specified using
C<set_dir_*> methods. If you only want to use C<MetaTrans::Base> as a base
class for your plug-in you can stop reading here. Everything you need to know
was written above.

If you are writting a plug-in from a scratch you have to make sure it provides
all the methods with appropriate functionality specified in this section. In
addition, every C<MetaTrans> plug-in has to provide attribute methods
as specified in L<ATTRIBUTES> section.

=cut

=over 4

=item $plugin->is_supported_dir($src_lang_code, $dest_lang_code)

Returns true value if the translation direction is supported from language with
C<$src_lang_code> to language with C<$dest_lang_code>, false value otherwise.

=cut

sub is_supported_dir
{
    my $self           = shift;
    my $src_lang_code  = shift;
    my $dest_lang_code = shift;

    return ${$self->{directions}}{$src_lang_code . "2" . $dest_lang_code};
}

=item $plugin->get_all_src_lang_codes

Returns a list of all language codes, which the plug-in is able to translate
from. For example, C<('eng', 'fre')> will be returned if supported translation
directions are:

    English -> French
    English -> Spanish
    French  -> Spanish

=cut

sub get_all_src_lang_codes
{
    my $self = shift;
    my @result;

    OUTER: foreach my $src_lang_code (@{$self->{language_keys}})
    {
        foreach my $dest_lang_code (@{$self->{language_keys}})
        {
            if ($self->is_supported_dir($src_lang_code, $dest_lang_code))
            {
                push @result, $src_lang_code;
                next OUTER;
            }
        }
    }

    return @result;
}

=item $plugin->get_dest_lang_codes_for_src_lang_code($src_lang_code)

Returns a list of all language codes, which the plug-in is able to translate
to from the language with $src_lang_code. If called with C<'eng'> as an
parameter in the above example, returned value would be C<('fre', 'spa')>.

=cut

sub get_dest_lang_codes_for_src_lang_code
{
    my $self          = shift;
    my $src_lang_code = shift;
    my @result;

    foreach my $dest_lang_code (@{$self->{language_keys}})
    {
        push @result, $dest_lang_code
            if $self->is_supported_dir($src_lang_code, $dest_lang_code);
    }

    return @result;
}

=item $plugin->translate($expression [, $src_lang_code, $dest_lang_code])

Returns translation of C<$expression> as an array of expression-translation
pairs in one string separated by C<" = "> in B<UTF-8 character encoding>.
An example output is:

    ("dog = chien", "dog = pitou", "dog days = canicule")

C<undef> value is returned and an error printed if C<< $src_lang_code
-> $dest_lang_code >> is an unsupported translation direction. C<'timeout'>
string is returned if timeout occurs when querying online translator,
C<'error'> string is returned on any other error.

Default translation direction (see C<default_dir> attribute) is used if
the method is called with first argument only.

=cut

sub translate
{
    my $self           = shift;
    my $expression     = shift;
    my $src_lang_code  = shift;
    my $dest_lang_code = shift;

    unless (scalar(keys %{$self->{directions}}) > 0)
    {
        carp "no supported directions defined";
        return 'error';
    }

    ($src_lang_code, $dest_lang_code) = $self->default_dir
        unless (defined $src_lang_code && defined $dest_lang_code);

    unless ($self->is_supported_dir($src_lang_code, $dest_lang_code))
    {
        carp "not supported direction: '${src_lang_code}2${dest_lang_code}'";
        return 'error';
    }

    my $ua = new LWP::UserAgent;
    $ua->cookie_jar({ file => "$ENV{HOME}/.metatrans.cookies.txt" });
    $ua->timeout($self->{timeout});

    # strip blanks
    $expression =~ s/\s+/ /g;
    $expression =~ s/^ //;
    $expression =~ s/ $//;

    my $request  = $self->create_request($expression, $src_lang_code,
        $dest_lang_code);
    my $response = $ua->request($request);

    if ($response->is_error())
    {
        if ($response->code =~ /50[03]/)
        {
            carp "timeout while translating '$expression'";
            return 'timeout';
        }
        else
        {
            carp "error (" . $response->code .
                ") while translating '$expression'";
            return 'error';
        }
    }
    my $content = $response->content();

    my @processed = $self->process_response($content, $src_lang_code,
        $dest_lang_code);
    my @result;

    my $at_bounds = $self->{match_at_bounds};
    while (@processed > 0)
    {
        my $left  = shift @processed;
        my $right = shift @processed;

        next unless
            $self->{matching} == M_EXACT ?
                &is_exact_match($expression, $left) :
            $self->{matching} == M_START ?
                &is_match_at_start($expression, $left, $at_bounds) :
            $self->{matching} == M_EXPR  ?
                &is_match_expr($expression, $left, $at_bounds) :
            $self->{matching} == M_WORDS ?
                &is_match_words($expression, $left, $at_bounds) :
            1;

        push @result, "$left = $right";
    }

    return @result;
}

=item $plugin->get_trans_command($expression, $src_lang_code, $dest_lang_code,
$append)

This method is a very ugly hack, for which writting C<MetaTrans> plug-ins from
a scratch is discouraged. See L<MetaTrans> for more information on why this
it is required.

The C<get_trans_command> method is expected to return an array containing
command, which if run using C<Proc::SyncExec::sync_popen_noshell> function
will print translations of C<$expression> from C<$src_lang_code> language to
C<$dest_lang_code> language (the first element of the array is the program
name, list of arguments follows). The command also needs to contain options
correspondent to current plug-in attribute values and ensure appropriate
behaviour. Each line of the output must correspond to one translation and
have following form:

    expression = translation

In addition, the C<$append string>, if specified, should be appendet to each
line of the output.

=cut

sub get_trans_command
{
    my $self           = shift;
    my $expression     = shift;
    my $src_lang_code  = shift;
    my $dest_lang_code = shift;
    my $append         = shift;

    my $class = ref($self);

#    $append     =~ s/"/\\"/g;
#    $expression =~ s/"/\\"/g;


#    my $command = "runtrans";
#    $command.= " $class";
#    $command.= " -t " . $self->{timeout};
#    $command.= " -m " . ($self->{matching} == M_EXACT ? 'exact' :
#                         $self->{matching} == M_START ? 'start' :
#                         $self->{matching} == M_EXPR  ? 'expr'  :
#                         $self->{matching} == M_WORDS ? 'words' :
#                                                        'all'  );
#    $command.= " -b " if $self->{match_at_bounds};
#    $command.= " -d " . $src_lang_code . "2" . $dest_lang_code;
#    $command.= " -a \"$append\"";
#    $command.= " \"$expression\"";

    my @command;
    push @command, "runtrans", $class;
    push @command, "-t", $self->{timeout};
    push @command, "-m", ($self->{matching} == M_EXACT ? 'exact' :
                          $self->{matching} == M_START ? 'start' :
                          $self->{matching} == M_EXPR  ? 'expr'  :
                          $self->{matching} == M_WORDS ? 'words' :
                                                         'all'  );
    push @command, "-b" if $self->{match_at_bounds};
    push @command, "-d", $src_lang_code . "2" . $dest_lang_code;
    push @command, "-a", $append;
    push @command, $expression;

    return @command;
}

=back

=cut

=head1 STATIC FUNCTIONS

=over 4

=item is_exact_match($in_expr, $found_expr)

Returns true value if the C<$found_expr> expression matches input expression
C<$in_expr> when using C<M_EXACT> matching options (see C<matching> attribute).

=cut

sub is_exact_match
{
    my $in_expr    = shift;
    my $found_expr = shift;

    return lc(&strip_grammar_info($in_expr)) eq
           lc(&strip_grammar_info($found_expr));
}

=item is_match_at_start($in_expr, $found_expr, $at_bounds)

Returns true value if the C<$found_expr> expression matches input expression
C<$in_expr> when using C<M_START> matching options (see C<matching> attribute).
The C<$at_bounds> argument corresponds to the C<match_at_bounds> attribute.

=cut

sub is_match_at_start
{
    my $in_expr    = shift;
    my $found_expr = shift;
    my $at_bounds  = shift;

    my $in_stripped    = &strip_grammar_info($in_expr);
    my $found_stripped = &strip_grammar_info($found_expr);

    return $at_bounds ?
        $found_stripped =~ /^\Q$in_stripped\E\b/g :
        $found_stripped =~ /^\Q$in_stripped\E/g   ;
}

=item is_match_expr($in_expr, $found_expr, $at_bounds)

Returns true value if the C<$found_expr> expression matches input expression
C<$in_expr> when using C<M_EXPR> matching options (see C<matching> attribute).
The C<$at_bounds> argument corresponds to the C<match_at_bounds> attribute.

=cut

sub is_match_expr
{
    my $in_expr    = shift;
    my $found_expr = shift;
    my $at_bounds  = shift;

    my $in_stripped    = &strip_grammar_info($in_expr);
    my $found_stripped = &strip_grammar_info($found_expr);

    return $at_bounds ?
        $found_stripped =~ /\b\Q$in_stripped\E\b/g :
        $found_stripped =~ /\Q$in_stripped\E/g     ;
}

=item is_match_words($in_expr, $found_expr, $at_bounds)

Returns true value if the C<$found_expr> expression matches input expression
C<$in_expr> when using C<M_WORDS> matching options (see C<matching> attribute).
The C<$at_bounds> argument corresponds to the C<match_at_bounds> attribute.

=cut

sub is_match_words
{
    my $in_expr    = shift;
    my $found_expr = shift;
    my $at_bounds  = shift;

    my $in_stripped    = &strip_grammar_info($in_expr);
    my $found_stripped = &strip_grammar_info($found_expr);

    foreach my $word (split /\W+/, $in_stripped)
    {
        return undef
            unless $at_bounds ?
                $found_stripped =~ /\b\Q$word\E\b/g :
                $found_stripped =~ /\Q$word\E/g     ;
    }

    return 1;
}

=item strip_grammar_info($expression)

Returns the C<$expression> with all the grammar and meaning information deleted
(everything in parantheses or behind a semicolon) B<in perl's internal UTF-8
format> (see L<Encode>).

=cut

sub strip_grammar_info
{
    my $expr = shift;
    $expr =  Encode::decode_utf8($expr)
        unless Encode::is_utf8($expr);
    $expr =~ s/\([^)]*\)//g;
    #$expr =~ s/, (r|e|s)\s*$//;
    $expr =~ s/;.*//;
    $expr =~ s/\W+/ /g;
    $expr =~ s/^ //;
    $expr =~ s/ $//;
    return $expr;
}

=item convert_to_utf8($input_encoding, $string)

Converts C<$string> from C<$input_encoding> to UTF-8 encoding. In addition all
HTML entities contained in the C<$string> are converted to corresponding
UTF-8 characters. This may sometimes be very useful when writting the
C<process_response> method.

=cut

sub convert_to_utf8
{
    my $input_encoding = shift;
    my $string         = shift;

    $string = Encode::decode($input_encoding, $string);
    my $str_unescaped = HTML::Entities::decode_entities($string);

    # $str_escaped might be in Perl's internal format, need to encode it
    return Encode::is_utf8($str_unescaped) ?
        Encode::encode_utf8($str_unescaped) :
        $str_unescaped;
}

=back

=cut

=head1 OTHER METHODS

=over 4

=item $plugin->run

Run the plug-in as a command line application. Very useful for testing and
debugging. Try executing following script to see what this does:

    #!perl

    # load a plug-in class derrived from MetaTrans::Base
    use MetaTrans::UltralinguaNet;

    # instantiate an object
    my $plugin = new MetaTrans::UltralinguaNet;

    # run it
    $plugin->run;

=cut

sub run
{
    my $self = shift;

    croak "no supported directions defined"
        unless (scalar(keys %{$self->{directions}}) > 0);

    my @options = $self->_get_options();
    return
        if @options < 7;

    my ($timeout, $matching, $at_bounds, $src_lang_code, $dest_lang_code,
        $append, $help) = @options;

    if ($help || @ARGV == 0)
    {
        $self->_print_usage();
        return;
    }

    $self->timeout($timeout);
    $self->match_at_bounds($at_bounds);
    $self->matching($matching);

    my $state;
    my $i = 0;
    foreach my $expr (@ARGV)
    {
        $i++;

        my @translations = $self->translate($expr, $src_lang_code,
            $dest_lang_code);

        if (@translations && $translations[0] !~ /=/)
        {
            $state = $translations[0];
            next;
        }
        $state = "ok";

        foreach my $trans (@translations)
            { print "$trans$append\n"; }

        print "\n" unless $i == @ARGV;
    }

    print $state . $append . "\n"
        if $append;
}

=back

=cut

################################################################################
# private methods                                                              #
################################################################################

sub _get_options
{
    my $self = shift;

    my $timeout = $self->{timeout};
    my $matching_str;
    my $matching = $self->{timeout};
    my $at_bounds;
    my $direction;
    my $help;
    my $append = '';

    Getopt::Long::Configure("bundling");
    GetOptions(
        't=i' => \$timeout,
        'm=s' => \$matching_str,
        'b'   => \$at_bounds,
        'd=s' => \$direction,
        'a=s' => \$append,
        'h'   => \$help,
    );

    if (defined $matching_str)
    {
        $matching_str eq 'exact' ? $matching = M_EXACT :
        $matching_str eq 'start' ? $matching = M_START :
        $matching_str eq 'expr'  ? $matching = M_EXPR  :
        $matching_str eq 'words' ? $matching = M_WORDS :
        $matching_str eq 'all'   ? $matching = M_ALL   :
            do
            {
                warn "invalid matching type: '$matching_str'\n";
                return undef;
            }
    }

    if (defined $direction && $direction !~ /2/)
    {
        warn "invalid direction format: '$direction'\n";
        return undef;
    }

    my ($src_lang_code, $dest_lang_code) = defined $direction ?
        split /2/, $direction :
        undef;

    return ($timeout, $matching, $at_bounds, $src_lang_code, $dest_lang_code,
        $append, $help);
}

sub _print_usage
{
    my $self     = shift;
    my $host     = $self->{host_server};
    my $script   = $self->{script_name};
    my $timeout  = $self->{timeout};
    my $matching = $self->{matching};

    unless (defined $script)
    {
        $script = $0;
        $script =~ s|^.*/||;
    }

    my ($def_exact, $def_start, $def_expr, $def_words, $def_all) =
        ('', '', '', '', '');

    my $def_str = '(def)';
    $matching == M_EXACT ? $def_exact = $def_str :
    $matching == M_START ? $def_start = $def_str :
    $matching == M_EXPR  ? $def_expr  = $def_str :
    $matching == M_WORDS ? $def_words = $def_str :
                           $def_all   = $def_str ;

    my ($def_src_lang_code, $def_dest_lang_code) = $self->default_dir();
    my ($wd, $wl, $wr) = $self->_get_column_widths();

    my @dir_options;
    foreach my $src_lang_code (@{$self->{language_keys}})
    {
        foreach my $dest_lang_code (@{$self->{language_keys}})
        {
            next unless $self->is_supported_dir($src_lang_code,
                $dest_lang_code);

            my $dir_option = sprintf("%-${wd}s: %-${wl}s -> %-${wr}s",
                $src_lang_code . "2" . $dest_lang_code,
                ${$self->{languages}}{$src_lang_code},
                ${$self->{languages}}{$dest_lang_code});

            $dir_option .= " (default)"
                if ($src_lang_code eq $def_src_lang_code &&
                    $dest_lang_code eq $def_dest_lang_code);

            push @dir_options, $dir_option;
        }
    }

    my $indent = "                     ";
    my $directions = join("\n$indent", @dir_options);

    print <<EOF;
Multilingual dictionary metasearcher for $host
Usage: $script [options] expression [...]\ttranslate word(s)

Options:
   --              expressions to be translated follow
   -t <timeout>    wait for the response for <timeout> secs (default $timeout)
   -m <matching>   set matching type
                     exact: exact match only $def_exact
                     start: match at start of the translated expr. only $def_start
                     expr : match expr. anywhere in the translated expr. $def_expr
                     words: match expr. words in the translated expr. $def_words
                     all  : match anything to anything $def_all
   -b              match at word boundaries only
   -d <direction>  set translation direction
                     $directions
   -a <string>     append <string> to each line of output
   -h              print this help screen
EOF
}

sub _get_column_widths
{
    my $self = shift;

    my $max_dir_width  = 0;
    my $max_lcol_width = 0;
    my $max_rcol_width = 0;
    
    foreach my $src_lang_code (@{$self->{language_keys}})
    {
        foreach my $dest_lang_code (@{$self->{language_keys}})
        {
            next unless $self->is_supported_dir($src_lang_code,
                $dest_lang_code);
            my $dir_width  = length($src_lang_code . "2" . $dest_lang_code);
            my $lcol_width = length(${$self->{languages}}{$src_lang_code});
            my $rcol_width = length(${$self->{languages}}{$dest_lang_code});

            $max_dir_width = $dir_width
                if $dir_width > $max_dir_width;

            $max_lcol_width = $lcol_width
                if $lcol_width > $max_lcol_width;

            $max_rcol_width = $rcol_width
                if $rcol_width > $max_rcol_width;
        }
    }

    return ($max_dir_width, $max_lcol_width, $max_rcol_width);
}

# borrowed from LWP::MemberMixin
sub _elem
{
    my($self, $elem, $val) = @_;
    my $old = $self->{$elem};
    $self->{$elem} = $val if defined $val;
    return $old;
}

1;

__END__

=head1 BUGS

Please report any bugs or feature requests to
C<bug-metatrans@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 AUTHOR

Jan Pomikalek, C<< <xpomikal@fi.muni.cz> >>

=head1 COPYRIGHT & LICENSE

Copyright 2004 Jan Pomikalek, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<MetaTrans>, L<MetaTrans::Languages>, L<MetaTrans::UltralinguaNet>,
L<HTTP::Request>, L<URI::Escape>
