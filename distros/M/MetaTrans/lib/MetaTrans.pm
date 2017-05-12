=head1 NAME

MetaTrans - Class for creating multilingual meta-translators

=head1 SYNOPSIS

    use MetaTrans;

    my $mt = new MetaTrans;

    # plug-ins we want to use
    my @plugin_classes = (
        'MetaTrans::UltralinguaNet',
        'MetaTrans::SlovnikCz',
        'MetaTrans::SeznamCz',
    );

    foreach my $plugin_class (@plugin_classes)
    {
        # load module
        eval "require $plugin_class";

        # instantiate
        my $plugin = new $plugin_class;

        # plug the plug-in in :)
        $mt->add_translators($plugin);
    }

    # plug-ins which support English to Czech translation
    @translators = $mt->get_translators_for_direction('eng', 'cze');

    # if we have at least one we will perform a translation of 'dog'
    if (@translators > 0)
    {
        $mt->run_translators('dog', 'eng', 'cze');
        my @translations;
        while (my $translation = $mt->get_translation)
            { push @translations, $translation; }

        # we want the output to be sorted
        my @sorted_translations = MetaTrans::sort_translations(@translations);
        print join("\n", @sorted_translations) . "\n";
    }

You are also encouraged to trying the Perl/Tk frontend. Simply run

    metatrans

=head1 DESCRIPTION

The C<MetaTrans> class provides an interface for making multilingual
translations using multiple data sources (translators). Its design
is especially suitable for extracting data from online translators
like L<http://www.ultralingua.net/>.

To do something useful a C<MetaTrans> object must be provided with
plug-ins for extracting data from every source to be used. By now
creating a plug-in from a scratch might be a bit complicated for 
some ugly hacks had to be made in the originally clean design of
C<MetaTrans> to make it working in Perl/Tk applications. Hopefully
this is going to change in some of the future releases.

Currently the only recommended way for creating C<MetaTrans> plug-ins
is by derriving from the C<MetaTrans::Base> class. See
L<MetaTrans::Base> for information on how to do so.

=cut

package MetaTrans;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT_OK);
use Exporter;
use MetaTrans::Base qw(:match_funcs);

use Carp;
use Encode;
use IO::Select;
use Proc::SyncExec qw(sync_fhpopen_noshell sync_popen_noshell);

$VERSION   = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf "%d."."%02d", @r };
@ISA       = qw(Exporter);
@EXPORT_OK = qw(sort_translations);

=head1 CONSTRUCTOR METHODS

=over 4

=item MetaTrans->new(@translators)

This method constructs a new MetaTrans object and returns it. Translators
array argument may be provided to plug in desired translators.

=cut

sub new
{
    my $class       = shift;
    my @translators = @_;

    my $self = bless {}, $class;
    $self->add_translators(@translators);
    
    return $self;
}

=back

=cut

=head1 METHODS

=cut

=over 4

=item $mt->add_translators(@translators)

Plug in one or more translators.

=cut

sub add_translators
{
    my $self        = shift;
    my @translators = @_;

    foreach my $trans (@translators)
    {
        push @{$self->{translators}}, $trans;
        $self->enable_translator($trans);
    }
}

=item $mt->get_translators

Return an array of all plug-ins being used.

=cut

sub get_translators
{
    my $self = shift;
    return @{$self->{translators}};
}

=item $mt->enable_translator($trans)

Enable the translator. The argument is an object.

=cut

sub enable_translator
{
    my $self  = shift;
    my $trans = shift;

    ${$self->{enabled}}{$trans} = 1;
}

=item $mt->disable_translator($trans)

Disable the translator. The argument is an object.

=cut

sub disable_translator
{
    my $self  = shift;
    my $trans = shift;

    ${$self->{enabled}}{$trans} = 0;
}

=item $mt->toggle_enabled_translator($trans)

Togle translator's enabled/disabled status. The argument is an object.

=cut

sub toggle_enabled_translator
{
    my $self  = shift;
    my $trans = shift;

    ${$self->{enabled}}{$trans} = not ${$self->{enabled}}{$trans};
}

=item $mt->is_enabled_translator($trans)

Returns true value if the translator is enabled, false otherwise.
The argument is an object.

=cut

sub is_enabled_translator
{
    my $self  = shift;
    my $trans = shift;

    return ${$self->{enabled}}{$trans};
}

=item $mt->get_translators_state($trans)

Returns current state of the translator. Possible values are

    VALUE       MEANING
    ---------   --------------------------------------------------------
    "ok"        successfully finished a translation (initial state, too)
    "busy"      working on a translation
    "timeout"   a timeout occured when querying an online translator
    "error"     unknown error occured when queryign an online translator

=cut

sub get_translators_state
{
    my $self  = shift;
    my $trans = shift;

    return "ok" unless exists ${$self->{state}}{$trans};
    return ${$self->{state}}{$trans};
}

=item $mt->get_all_src_lang_codes

Returns a list of language codes, which some of the enabled plug-ins are
able to translate from.

The method calls the C<get_all_src_lang_codes> method for all enabled
plug-ins (see L<MetaTrans::Base>) and unions results.

=cut

sub get_all_src_lang_codes
{
    my $self = shift;
    my @codes;
    my %codes_hash;
    
    foreach my $trans (@{$self->{translators}})
    {
        next unless $self->is_enabled_translator($trans);
        foreach my $code ($trans->get_all_src_lang_codes)
        { 
            push @codes, $code
                unless $codes_hash{$code};
            $codes_hash{$code} = 1;
        }
    }

    return @codes;
}

=item $mt->get_dest_lang_codes_for_src_lang_code($src_lang_code)

Returns a list of language codes, which some of the enabled plug-ins are
able to translate to from the language with $src_lang_code.

The method calls the C<get_dest_lang_codes_for_src_lang_codes> method for
all enabled plug-ins (see L<MetaTrans::Base>) and unions results.

=cut

sub get_dest_lang_codes_for_src_lang_code
{
    my $self          = shift;
    my $src_lang_code = shift;
    my @codes;
    my %codes_hash;

    foreach my $trans (@{$self->{translators}})
    {
        next unless $self->is_enabled_translator($trans);
        foreach my $code
            ($trans->get_dest_lang_codes_for_src_lang_code($src_lang_code))
        {
            push @codes, $code
                unless $codes_hash{$code};
            $codes_hash{$code} = 1;
        }
    }

    return @codes;
}

=item $mt->get_translators_for_direction($src_lang_code, $dest_lang_code)

Retuns an array of enabled tranlators, which support the translation direction
from language with C<$src_lang_code> to language with C<$dest_lang_code>.

=cut

sub get_translators_for_direction
{
    my $self           = shift;
    my $src_lang_code  = shift;
    my $dest_lang_code = shift;
    my @result;

    foreach my $trans (@{$self->{translators}})
    {
        next unless $self->is_enabled_translator($trans);
        push @result, $trans
            if $trans->is_supported_dir($src_lang_code, $dest_lang_code);
    }

    return @result;
}

=item $mt->run_translators($expression, $src_lang_code, $dest_lang_code,
%options)

Perform a translation of C<$expression> from C<$src_lang_code> language to
C<$dest_lang_code> language simultaneously on all enabled translators
(plug-ins), which support this translation direction. The method returns
true value on success, false on error. Use C<get_translation> method for
retrieving the results of particular translations.

The method sets the state of all plug-ins to C<"busy">. See C<get_state>
method.

There are two ways of performing parallel run. If C<$options{tk_safe}> is
undefined or set to false value, then a child process is forked for every
translator to be used and C<translate> method is called. This is generally
cleaner and more effective way of doing so then the one mentioned bellow.
However, this causes trouble if the module is used in Perl/Tk applications.

If C<$options{tk_safe}> is set to a true value, then a brand new child
process is created for every plug-in to be used. For this plug-ins are
required to implement C<get_trans_command> method, which is expected to
return a string containing a command, which can be run from a shell and
provides appropriate functionality for the translation to be performed.
This is an ugly hack necessary for making C<MetaTrans> work in Perl/Tk
applications. Hopefully this will be fixed in some of the future releases.
See also L<MetaTrans::Base> for more information on this.

Generally, if the plug-ins are only to be run with C<$options{tk_safe}> set to
false, they are not required to implement the C<get_trans_command> method.
Reversely, if the plug-ins are only to be run with C<$options{tk_safe}>
set to true, the are not required to implement the C<translate> method.
Plug-ins derrived from C<MetaTrans::Base> implement both methods.

=cut

sub run_translators
{
    my $self           = shift;
    my $expression     = shift;
    my $src_lang_code  = shift;
    my $dest_lang_code = shift;
    my %options        = @_;

    my @translators = $self->get_translators_for_direction(
        $src_lang_code, $dest_lang_code);
    if (@translators == 0)
    {
        Carp::cluck "no translators available for direction: " . 
            "'${src_lang_code}2${dest_lang_code}'";
        return undef;
    }

    $self->{running} = 0;
    undef $self->{pids};
    $self->{select} = new IO::Select();
    my @fhs;
    my $i = 0;

    foreach my $translator (@translators)
    {
        my $pid;
        if ($options{tk_safe})
        {
            # tk-safe fork
            my $translator_id = $self->_get_trans_id($translator);
            my @command = $translator->get_trans_command($expression,
                $src_lang_code, $dest_lang_code, "/$translator_id");

            ($fhs[$i], $pid) = sync_popen_noshell('r', @command);
            unless($pid)
            {
                carp("can't run '@command', make sure that runtrans is ".
                    "in your \$PATH variable");
                return undef;
            }
        }
        else
        {
            # non-tk-safe fork
            do
            {
                $pid = open($fhs[$i], '-|');
                unless (defined $pid)
                {
                    warn "cannot fork: $!, still trying...";
                    sleep 2;
                }
            }
            until defined $pid;
        }

        ${$self->{state}}{$translator} = "busy";

        if ($pid)
        {
            # parent
            push @{$self->{pids}}, $pid;
            $self->{select}->add($fhs[$i]);
            $self->{running}++;
        }
        else
        {
            #child (non-tk-safe fork only)
            $self->_run_process($translator, $expression, $src_lang_code,
                $dest_lang_code);
        }
    }
    continue
        { $i++; }

    return 1;
}

=item $mt->get_translation(%options)

Returns a translation returned by one of the running plug-ins (translators)
as a string of following form:

    expression = translation

The method blocks until there is a translation is available (until some of
the running plug-ins is ready to provide an output). The order, in which
the translations are returned depends on the order, in which the translators
return their result and is therefore non-deterministic.

The behaviour of the method depends on the C<$options{return_translators}>
option. If undefined or set to a false value then every call returns one
translation, C<undef> value is returned to indicate the end.

If C<$options{return_value}> is set to true value, the every call returns a
(translation, translator) pair in an array, where the translator is the one,
which returned the translation. (C<undef>, translator) pair is returned to
indicate that the translator finished running and. C<undef> value is returned
to indicate that no more translations are available.

The method also sets states of particular translators. See C<get_state> method.

=cut

sub get_translation
{
    my $self    = shift;
    my %options = @_;

    return undef
        if $self->{running} == 0;

    while (1)
    {
        my @ready;
        do { @ready = $self->{select}->can_read(0.1); } until @ready > 0;

        my $fh = shift @ready;
        chomp(my $translation = <$fh>);

        $translation =~ s|/([0-9]+)$||;
        my $translator_id = $1;

        if ($translation =~ /^(ok|error|timeout)$/)
        {
            my $translator = $self->_get_trans_by_id($translator_id);
            ${$self->{state}}{$translator} = $translation;
            $translation = '';

            $self->{running}--;
            $self->{select}->remove($fh);
            $fh->close;
        }

        return ($translation, $self->_get_trans_by_id($translator_id))
            if $options{return_translators};

        # return translations only
        return undef
            if $self->{running} == 0;
        return $translation
            unless $translation eq '';
    }
}

=item $mt->is_translation_available($timeout)

A non-blocking call, which returns a true value if next translation is already
available. Otherwise it blocks for at most C<$timeout> seconds and then returns
false if a translation is still unavailable. However, if the C<$timeout> is
undefined then the method always blocks and never returns false value.

It is useful if you want to do something while waiting for the next
translation. Example:

    LOOP: while (1)
    {
        # check every second
        until ($mt->is_translation_available(1.0))
        {
            last LOOP
                if &something_happened;
        }

        my $translation = $mt->get_translation;

        # ... do something with $translation ...
    }

Note: To be more exact, the C<is_translation_available> returns a true value if
the C<get_translation_method> has something to say. This must not necessairly
be a next translation, but also an C<undef> value or (<undef>, translator)
pair.

=cut

sub is_translation_available
{
    my $self    = shift;
    my $timeout = shift;

    return 1
        if $self->{running} == 0;

    my @handles = $self->{select}->handles;
    return 1
        if @handles  = 0;

    my @ready = $self->{select}->can_read($timeout);
    return (@ready > 0);
}

=item $mt->stop_translators

Stop all running plug-ins. This simply kills all running child processes.
The correspondent translators will end in the C<"busy"> state.

=cut

sub stop_translators
{
    my $self = shift;

    kill(9, @{$self->{pids}});
    foreach my $fh ($self->{select}->handles)
        { $fh->close; }
}

=back

Following methods set correspondent attributes of all plug-ins being used
to specified values. See C<ATTRIBUTES> section of L<MetaTrans::Base> for
more information.

=over 4

=item $mt->set_timeout($timeout)

=item $mt->set_matching($type)

=item $mt->set_match_at_bounds($bool)

=back

=cut

sub set_timeout
{
    my $self    = shift;
    my $timeout = shift;

    foreach my $trans (@{$self->{translators}})
        { $trans->timeout($timeout); }
}

sub set_matching
{
    my $self     = shift;
    my $matching = shift;

    foreach my $trans (@{$self->{translators}})
        { $trans->matching($matching); }
}

sub set_match_at_bounds
{
    my $self      = shift;
    my $at_bounds = shift;

    foreach my $trans (@{$self->{translators}})
        { $trans->match_at_bounds($at_bounds); }
}

=head1 FUNCTIONS

=over 4

=item sort_translations($expression, @translations)

Returns an array of translations sorted by relevance to the C<$expression>.
In addition, any duplicate information is removed.

=back

=cut

sub sort_translations
{
    my $expr         = shift;
    my @translations = @_;

    # sort
    my @trans_sorted = sort { 
        &_translation_order_index($expr, $b) <=> &_translation_order_index($expr, $a)
        ||
        decode_utf8($a) cmp decode_utf8($b)
    } @translations;

    # make unique
    my @result;
    my @same;
    my $last_same;

    while (1)
    {
        my $trans = shift @trans_sorted;

        if (@same == 0 || $trans && &_eq_stripped($trans, $last_same))
        {
            $last_same = $trans;
            push @same, $last_same;
            next unless @trans_sorted == 0;
        }

        # if the translations are the same when stripping the grammar info
        # then only the longest one is kept
        my $longest = '';
        foreach (@same)
        {
            $longest = $_
                if length($_) > length($longest);
        }
        push @result, $longest;

        $last_same = $trans;
        @same = ($last_same);

        last unless $trans;
    }

    return @result;
}

################################################################################
# private methods                                                              #
################################################################################

# runs a translation in a child process (tk-safe fork)
sub _run_process
{
    my $self           = shift;
    my $translator     = shift;
    my $expression     = shift;
    my $src_lang_code  = shift;
    my $dest_lang_code = shift;

    my $translator_id = $self->_get_trans_id($translator);
    my @translations  = $translator->translate($expression,
        $src_lang_code, $dest_lang_code);
    
    if (@translations && $translations[0] !~ /=/)
    {
        print $translations[0] . "\n";
        exit;
    }
    
    foreach my $trans (@translations)
        { print "$trans/$translator_id\n"; }

    print "ok/$translator_id\n";
    exit;
}

# returns a number indicating relevance of a translation ($trans) to the
# searched expression ($expr); this is used for ordering the translations
sub _translation_order_index
{
    my $expr  = shift;
    my $trans = shift;
    my $index = 0;

    my ($trans_left) = split / = /, $trans;

    $index += 1
        if is_match_words($expr, $trans_left, 1);
    $index *= 10;

    $index += 1
        if is_match_words($expr, $trans_left, 0);
    $index *= 10;

    $index += _words_matched($expr, $trans_left, 1);
    $index *= 10;

    $index += _words_matched($expr, $trans_left, 0);
    $index *= 100;

    my @words = split /\W+/, MetaTrans::Base::strip_grammar_info($trans_left);
    $index -= @words;
    $index *= 100;

    $index += 1
        if is_match_at_start($expr, $trans_left, 0);
        #$index *= 100;

    return $index;
}

# returns true value if the two translations with grammar information stripped
# are equal
sub _eq_stripped
{
    my $trans1 = shift;
    my $trans2 = shift;

    $trans1 = Encode::decode_utf8($trans1)
        unless Encode::is_utf8($trans1);
    $trans2 = Encode::decode_utf8($trans2)
        unless Encode::is_utf8($trans2);

    my ($left1, $right1) = split(/ = /, $trans1);
    my ($left2, $right2) = split(/ = /, $trans2);

    $left1 = MetaTrans::Base::strip_grammar_info($left1);
    $left2 = MetaTrans::Base::strip_grammar_info($left2);

    return $left1 eq $left2 && $right1 eq $right2;
}

# returns the plugin with an internal ID ($id),
# or undef
sub _get_trans_by_id
{
    my $self = shift;
    my $id   = shift;

    return ${$self->{translators}}[$id];
}

# returns an internal ID of a plugin,
# or -1 if this plugin is not used
sub _get_trans_id
{
    my $self  = shift;
    my $trans = shift;

    my @translators = @{$self->{translators}};
    for my $i (0 .. $#translators)
    {
        return $i
            if $trans eq $translators[$i];
    }

    return -1;
}

# returns number of words of $in_expr matched in $found_expr
sub _words_matched
{
    my $in_expr    = shift;
    my $found_expr = shift;
    my $at_bounds  = shift;

    my $in_stripped    = MetaTrans::Base::strip_grammar_info($in_expr);
    my $found_stripped = MetaTrans::Base::strip_grammar_info($found_expr);

    my $count = 0;
    while ($in_stripped =~ /(\w+)/g)
    {
        my $word = $1;
        if ($at_bounds)
        {
            $count++
                if $found_stripped =~ /\b$word\b/;
        }
        else
        {
            $count++
                if $found_stripped =~ /$word/;
        }
    }

    return $count;
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

L<MetaTrans::Base>, L<MetaTrans::Languages>, L<MetaTrans::UltralinguaNet>,
L<Encode>
