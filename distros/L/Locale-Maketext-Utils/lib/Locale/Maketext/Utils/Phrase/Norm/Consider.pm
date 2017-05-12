package Locale::Maketext::Utils::Phrase::Norm::Consider;

use strict;
use warnings;
use Locale::Maketext::Utils::Phrase ();

sub normalize_maketext_string {
    my ($filter) = @_;

    my $string_sr = $filter->get_string_sr();

    my $struct = Locale::Maketext::Utils::Phrase::phrase2struct( ${$string_sr} );

    # entires phrase is bracket notation
    if ( Locale::Maketext::Utils::Phrase::struct_is_entirely_bracket_notation($struct) ) {
        ${$string_sr} .= "[comment,does this phrase really need to be entirely bracket notation?]";
        $filter->add_warning('Entire phrase is bracket notation, is there a better way in this case?');
    }

    my $idx          = -1;
    my $has_bare     = 0;
    my $has_hardurl  = 0;
    my $last_idx     = @{$struct} - 1;
    my $bn_var_rexep = Locale::Maketext::Utils::Phrase::get_bn_var_regexp();

    for my $piece ( @{$struct} ) {
        $idx++;
        next if !ref($piece);

        my $before = $idx == 0 ? '' : $struct->[ $idx - 1 ];
        my $bn     = $piece->{'orig'};
        my $after  = $idx == $last_idx ? '' : $struct->[ $idx + 1 ];

        if ( $piece->{'type'} eq 'var' || $piece->{'type'} eq 'basic_var' ) {

            # unless the “bare” bracket notation  …
            unless (
                ( $idx == $last_idx && $before =~ m/\:(?:\x20|\xc2\xa0)/ && ( !defined $after || $after eq '' ) )    # … is a trailing '…: [_2]'
                #tidyoff
                or (
                    ( $before !~ m/(?:\x20|\xc2\xa0)$/ && $after !~ m/^(?:\x20|\xc2\xa0)/ ) # … is surrounded by non-whitespace already
                    &&
                    ( $before !~ m/[a-zA-Z0-9]$/ && $after !~ m/^[a-zA-Z0-9]/ )             # … and that non-whitespace is also non-alphanumeric (TODO target phrases need a lookup)
                )
                #tidyon
                or ( $before =~ m/,(?:\x20|\xc2\xa0)$/        && $after =~ m/^,/ )                                        # … is in a comma reference
                or ( $before =~ m/\([^\)]+(?:\x20|\xc2\xa0)$/ && $after =~ m/^\)/ )                                       # … is at the end of parenthesised text
                or ( $before =~ m/\($/                        && $after =~ m/(?:\x20|\xc2\xa0)[^\)]+\)/ )                 # … is at the beginning of parenthesised text
                or ( $before =~ m/(?:\x20|\xc2\xa0)$/         && $after =~ m/’s(?:\x20|\xc2\xa0|;.|,.|[\!\?\.\:])/ )    # … is an apostrophe-s (curly so its not markup!)

              ) {
                ${$string_sr} =~ s/(\Q$bn\E)/“$1”/;
                $has_bare++;
            }
        }

        # Do not hardcode URL in [output,url]:
        if ( $piece->{'list'}[0] eq 'output' && $piece->{'list'}[1] eq 'url' ) {
            if ( $piece->{'list'}[2] !~ m/\A$bn_var_rexep\z/ ) {
                my $last_idx_bn = @{ $piece->{'list'} } - 1;
                my $url         = $piece->{'list'}[2];
                my $args        = @{ $piece->{'list'} } > 3 ? ',' . join( ',', @{ $piece->{'list'} }[ 3 .. $last_idx_bn ] ) : '';

                ${$string_sr} =~ s/(\Q$bn\E)/\[output,url,why hardcode “$url”$args\]/;
                $has_hardurl++;
            }
        }
    }

    $filter->add_warning('Hard coded URLs can be a maintenance nightmare, why not pass the URL in so the phrase does not change if the URL does') if $has_hardurl;
    $filter->add_warning('Bare variable can lead to ambiguous output')                                                                            if $has_bare;

    return $filter->return_value;
}

1;

__END__

=encoding utf-8

=head1 Normalization

The checks in here are for various best practices to consider while crafting phrases.

=head2 Rationale

These are warnings only and are meant to help point out things that typically are best done differently but could possibly be legit and thus a human needs to consider and sort it out.

=head1 possible violations

None

=head1 possible warnings

=over 4

=item Entire phrase is bracket notation, is there a better way in this case?

This will append '[comment,does this phrase really need to be entirely bracket notation?]' to the phrase.

The idea behind it is that a phrase that is entirely bracket notation is a sure sign that it needs done differently.

For example:

=over 4

=item method

    $lh->maketext('[numf,_1]',$n);

There is no need to translate that, it’d be the same in every locale!

You would simply do this:

    $lh->numf($n)

=item overly complex

    $lh->maketext('[boolean,_1,Your foo has been installed.,Your foo has been uninstalled.]',$is_install);

Unnecessarily difficult to read/work with and without benefit. You can't use any other bracket notation. You can probably spot other issues too.

Depending on the situation you might do either of these:

    if ($is_install) {
        $lh->maketext('Your foo has been installed.');
    }
    else {
        $lh->maketext('Your foo has been uninstalled.');
    }

or if you prefer to keep the variant–pair as one unit:

    $lh->maketext('Your foo has been [boolean,_1,installed,uninstalled].',$is_install);

=back

=item Hard coded URLs can be a maintenance nightmare, why not pass the URL in so the phrase does not change if the URL does

     $lh->maketext('You can [output,url,http://support.example.com,visit our support page] for further assistance.');

What happens when support.example.com changes to custcare.example.com? You have to change, not only the caller but the lexicons and translations, ick!

Then after you do that your boss says, oh wait actually it needs to be customer.example.com …

But if you had passed it in as an argument:

     $lh->maketext('You can [output,url,_1,visit our support page] for further assistance.', $url_db{'support_url'});

Now when support.example.com changes to custcare.example.com you update 'support_url' in %url_db–done.

He wants it to be customer.example.com, no problem update 'support_url' in %url_db–done.

=item Bare variable can lead to ambiguous output

    $lh->maketext('The checksum was [_1].', $sum);

If $sum is empty or undef you get odd spacing (e.g. “was .” instead of “was.”), could lose info, (e.g. “wait, the checksum is what now?”), or change meaning completely (e.g. what if the checksum was the string “BAD”).

    'The checksum was .'
    'The checksum was BAD.' # what! my data is corrupt ⁈

That applies even if it is decorated some way:

    'The checksum was <code></code>.'
    'The checksum was <code>BAD</code>.' # what my data is corrupt ⁈

It promotes evil partial phrases (i.e. that are untranslatable which is sort of the opposite of localizing things no?)

    $lh->maketext('The checksum was [_1].', $lh->maketext('inserted into the database)); # !!!! DON’T DO THIS !!!!

One way to visually distinguish what you intend regardless of the value given is simply to quote it:

   The checksum was “[_1]”.

becomes:

   The checksum was “”.                    # It is obvious that the sum is empty
   The checksum was “ ”.                   # It is obvious that the sum is all whitespace
   The checksum was “BAD”.                 # It is obvious that it is a string made up of B, A, and D and not a statement that the sum has a problem
   The checksum was “perfectly awesome”.   # It looks weird so someone probably will notice and ask you to fix your code

In other words:

=over 4

=item I<Using “ and ” disambiguates the entire string’s intent.> No accidental or malicious meaning changes.

=item  I<They also provide substance to a variable that may very well be null.>

For browsers, any span-level tag which is empty is not expressed in the rendering of the page. Therefore if we wrap variable expressions in span-level DOM, the user stands a very real chance of seeing incompleteness or potentially not noticing errors at all.

=item  I<Having this dis-ambiguation also assists the translator:>

=over 4

=item They can use whatever their locale uses without needing bracket notation (e.g. « and »).

This allows for flexibility since brakcet notation is not nestable (and should not be since it isn’t a templating engine).

=item When the translators see <strong> or any other wrapping element in the phrase, they will not immediately know what’s going on.

=back

=item I<It helps programmers make better choices.>

=back

I<Perhaps quotes are the wrong thing in a given instance:> Depending on what you’re doing other things might work too:

=over 4

=item Trailing introductory “:”:

   An error has occured: [_2]

=item Alternate text:

   Sorry, [is_defined,_2,“_2” is an invalid,you must specify a valid] value for “[_1]”.

=item Parentheses:

   The domain ([_1]) could not be found.

   The clown (AKA [_1]) is down.

   The network ([_1] in IPv6) is up.

=item Comma reference:

   The user, [_1], already exists.

=item Etc etc

=back

=back

=head1 Checks only run under extra filter mode:

None.
