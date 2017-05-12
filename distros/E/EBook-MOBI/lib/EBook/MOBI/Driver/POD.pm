package EBook::MOBI::Driver::POD;

our $VERSION = '0.72'; # VERSION (hook for Dist::Zilla::Plugin::OurPkgVersion)

use strict;
use warnings;

use Pod::Parser;
use EBook::MOBI::Driver;
our @ISA = qw(Pod::Parser EBook::MOBI::Driver);

use Text::Trim;
use HTML::Entities;
use Carp;
use EBook::MOBI::Converter;
use IO::String;

# This constants are used for internal replacement
# See interior_sequence() and _html_enc() for usage
use constant { GT  => '1_qpdhcn_thisStringShouldNeverOccurInInput',
               LT  => '2_udtcqk_thisStringShouldNeverOccurInInput',
               AMP => '3_pegjyq_thisStringShouldNeverOccurInInput',
               COL => '4_jdkmso_thisStringShouldNeverOccurInInput',
               QUO => '5_wuehlo_thisStringShouldNeverOccurInInput',
               DQUO=> '6_jrgwpm_thisStringShouldNeverOccurInInput',
             };

# IMPORTANT
# This constant ist JUST a shortcut for readability.
# Because it is used in hases ($parser->{}) a + is used so that it is not
# interpreted as a string, so it looks like this: $parser->{+P . 'bla'}
# See http://perldoc.perl.org/constant.html for details
use constant { P   => 'EBook_MOBI_Pod2Mhtml_' };

# Overwrite sub of Pod::Parser
sub begin_input {
    my $parser = shift;
    my $out_fh = $parser->output_handle();       # handle for parsing output

    $parser->{+P . 'toMobi'} = EBook::MOBI::Converter->new();

    $parser->debug_msg('found POD, parsing...');

    # make sure that this variable is set to 0 at beginning
    $parser->{+P . 'listcontext'} = 0;
    $parser->{+P . 'listjustwentback'} = 0;
    $parser->{+P . 'begin'} = '';
}

# Overwrite sub of Pod::Parser
sub end_input {
    my $parser = shift;
    my $out_fh = $parser->output_handle();

    $parser->debug_msg('...end of POD reached');
}

# Overwrite sub of Pod::Parser
# Here all POD commands starting with '=' are handled
sub command { 
    my ($parser, $command, $paragraph, $line_num) = @_; 
    my $out_fh = $parser->output_handle();       # handle for parsing output

    # IMAGE is an unofficial command introduced by Renee, its very simple:
    # =image PATH_TO_IMAGE ANY TEXT FOLLOWING UNTIL END OF LINE
    if ($command eq 'image') {

        print
            "WARNING: the unofficial POD command '=image' is deprecated.\n";

        # With this regex we parse the content, coming with the command.
        # An example could look like this:
        # $paragraph = '/home/user/picture.jpg Pic1: A Camel'
        if ($paragraph =~ m/(\S*)\s*(.*)/g) {
            my $img_path = $1;  # e.g.: '/home/user/picture.jpg'
            my $img_desc = $2;  # e.g.: 'A Camel'

            # We convert special chars to HTML, but only in the
            # description, not in the path!
            $img_desc = _html_enc($img_desc);

            # We print out an html image tag.
            # e.g.: <img src="/home/user/picture.jpg" recindex="1">
            # recindex is MOBI specific, its the number of the picture,
            # pointing into the picture records of the Mobi-format
            print $out_fh
                $parser->{+P . 'toMobi'}
                    ->image($img_path, $img_desc);
        }
    }
    # POD compatible additional syntax to process images
    # =for image PATH_TO_IMAGE ANY TEXT FOLLOWING UNTIL END OF LINE
    if ($command eq 'for') {

        # With this regex we parse the content, coming with the command.
        # An example could look like this:
        # $paragraph = 'image /home/user/picture.jpg Pic1: A Camel'
        if ($paragraph =~ m/image\s*(\S*)\s*(.*)/g) {
            my $img_path = $1;  # e.g.: '/home/user/picture.jpg'
            my $img_desc = $2;  # e.g.: 'A Camel'

            # We convert special chars to HTML, but only in the
            # description, not in the path!
            $img_desc = _html_enc($img_desc);

            # We print out an html image tag.
            # e.g.: <img src="/home/user/picture.jpg" recindex="1">
            # recindex is MOBI specific, its the number of the picture,
            # pointing into the picture records of the Mobi-format
            print $out_fh
                $parser->{+P . 'toMobi'}
                    ->image($img_path, $img_desc);
        }
    }
    # Lists are a bit complex. The commands 'over', 'back' and 'item'
    # are used. They exchange state over a global variable. This state
    # is the listcontext, which can be: 'begin', 'ul' or 'ol'.
    # OVER: starts the listcontext
    elsif ($command eq 'over') {

        # If we reach an 'over' command we can't do anything yet
        # because we don't know if it will be an ordered or an
        # unordered list! So we just set a global variable to 'begin',
        # the first item call can then know that it is the first item
        # and that it defines the rest of the list type.

        if (exists $parser->{+P . 'list'}) {
            # if we reach here, this means that this is a nested list
            $parser->{+P . 'listlvl'}++;
        }
        else {
            $parser->{+P . 'listlvl'} = 0;
        }


        push @{$parser->{+P . 'list'}}
             , {
                 type    => ''     ,
                 items   => 0      ,
                 state   => 'over' ,
                 contentInCmd => 1 ,
                 blockquotes  => 0 ,
               };
    }
    # BACK: ends the listcontext
    elsif ($command eq 'back') {

        my $lvl = $parser->{+P . 'listlvl'};

        # print end-tag according to the lists type
        if ($parser->{+P . 'list'}->[$lvl]->{type} eq 'ul') {
            print $out_fh '</li>' . "\n"; # close last item
            print $out_fh '</ul>' . "\n";
        }
        elsif ($parser->{+P . 'list'}->[$lvl]->{type} eq 'ol') {
            print $out_fh '</li>' . "\n"; # close last item
            print $out_fh '</ol>' . "\n";
        }
        elsif
          ($parser->{+P . 'list'}->[$lvl]->{type}
           eq 'blockquote') {
            # list is processed
            # there where no items...
        }
        else {
            carp 'POD parsing error. Undefined listcontext: '
                  . $parser->{+P . 'listcontext'};
        }

        # DELETE if list is finish
        if ($parser->{+P . 'listlvl'} == 0) {
            delete $parser->{+P . 'listlvl'};
            delete $parser->{+P . 'list'};
            delete $parser->{+P . 'listjustwentback'};
        }
        else {
            $parser->{+P . 'list'}->[$lvl]->{state} = 'back';
            $parser->{+P . 'listlvl'}--;
            $parser->{+P . 'listjustwentback'} = 1;
        }
    }
    # CUT: end of POD
    elsif ($command eq 'cut') {
        # We don't need to do anything here...
    }
    elsif ($command eq 'begin') {
        if ($paragraph =~ m/^\W*(\w+)\W*$/) {
            my $begin_name = $1;
            $parser->{+P . 'begin'} = $begin_name;
        }
    }
    elsif ($command eq 'end') {
        if ($paragraph =~ m/^\W*(\w+)\W*$/) {
            my $end_name = $1;
            if ($parser->{+P . 'begin'} eq $end_name) {
                $parser->{+P . 'begin'} = '';
            }
            else {
                croak 'no nested begin/end supported';
            }
        }
    }
    # if we reach this ELSE, this means that the command can only be
    # of type HEAD or ITEM (so they contain some text!)
    else {
        # first we remove all whitespace from begin and end of the title
        trim $paragraph;
        # then we call interpolate so that 'interior_sequence' is called.
        # this is replacing inline POD.
        my $expansion = $parser->interpolate($paragraph, $line_num);
        # then we replace special chars with HTML entities
        $expansion = _html_enc($expansion);

        # Now we just need to print the text with the matching HTML tag
        if ($command eq 'head0') {
            # head0 gets only printed if the option is set!
            # (head0 is not official POD standard)
            if ($parser->head0_mode()) {
                # before every head1 we insert a "mobi-pagebreak"
                # but not before the first one!
                if (exists $parser->{+P . 'firstH1passed'}
                and exists $parser->{+P . 'pages'}
                and        $parser->{+P . 'pages'}
                ) {
                    print $out_fh
                        $parser->{+P . 'toMobi'}->pagebreak();
                }
                else {
                    $parser->{+P . 'firstH1passed'} = 1;
                }

                print $out_fh
                    $parser->{+P . 'toMobi'}->title($expansion, 1);
            }
        }
        elsif ($command eq 'head1') {
            # we need to check to which level we translate the headings...
            if ($parser->head0_mode()) {
                print $out_fh
                    $parser->{+P . 'toMobi'}->title($expansion, 2);
            }
            else {
                # before every head1 we insert a "mobi-pagebreak"
                # but not before the first one!
                if (exists $parser->{+P . 'firstH1passed'}
                and exists $parser->{+P . 'pages'}
                and        $parser->{+P . 'pages'}
                ) {
                    print $out_fh
                        $parser->{+P . 'toMobi'}->pagebreak();
                }
                else {
                    $parser->{+P . 'firstH1passed'} = 1;
                }

                print $out_fh
                    $parser->{+P . 'toMobi'}->title($expansion, 1);
            }
        }
        elsif ($command eq 'head2') {
            # we need to check to which level we translate the headings...
            if ($parser->head0_mode()) {
                print $out_fh
                    $parser->{+P . 'toMobi'}->title($expansion, 3);
            }
            else {
                print $out_fh
                    $parser->{+P . 'toMobi'}->title($expansion, 2);
            }
        }
        elsif ($command eq 'head3') {
            # we need to check to which level we translate the headings...
            if ($parser->head0_mode()) {
                print $out_fh
                    $parser->{+P . 'toMobi'}->title($expansion, 4);
            }
            else {
                print $out_fh
                    $parser->{+P . 'toMobi'}->title($expansion, 3);
            }
        }
        elsif ($command eq 'head4') {
            # we need to check to which level we translate the headings...
            if ($parser->head0_mode()) {
                print $out_fh
                    $parser->{+P . 'toMobi'}->title($expansion, 5);
            }
            else {
                print $out_fh
                    $parser->{+P . 'toMobi'}->title($expansion, 4);
            }
        }
        # ITEM: lists items
        elsif ($command eq 'item') {

            # If we are still in listcontext 'begin' this means that this is
            # the first item of the list, which will be used to figure out
            # the type of the list.
            my $lvl = $parser->{+P . 'listlvl'};

            $parser->{+P . 'list'}->[$lvl]->{items}++;

            if ($parser->{+P . 'list'}->[$lvl]->{items} == 1){

                # if we are already in a list...
                if ($parser->{+P . 'list'}->[$lvl]->{state}
                    eq 'over'
                    and $lvl > 0
                    and
                    $parser->{+P . 'list'}->[$lvl-1]->{items}
                    > 0
                    ) {
                    # we need to close the last item!
                    print $out_fh '</li>' . "\n";
                }

                # is there a digit at first, if yes this is an ordered list
                if ($expansion =~ /^\s*\d+\s*(.*)$/) {
                    $expansion = $1;
                    $parser->{+P . 'list'}->[$lvl]
                           ->{type} = 'ol';

                    if ($expansion =~ /[[:alnum:][:punct:]]+/) {
                        print $out_fh '<ol>' . "\n";
                    }
                    else {
                        $parser->{+P . 'list'}->[$lvl]->{contentInCmd} = 0;
                        print $out_fh "<ol>\n";
                    }
                }
                # is there a '*' at first, if yes this is an unordered list
                elsif ($expansion =~ /^\s*\*{1}\s*(.*)$/) {
                    $expansion = $1;
                    $parser->{+P . 'list'}->[$lvl]->{type} = 'ul';

                    if ($expansion =~ /[[:alnum:][:punct:]]+/) {
                        print $out_fh '<ul>' . "\n";
                    }
                    else {
                        $parser->{+P . 'list'}->[$lvl]->{contentInCmd} = 0;
                        print $out_fh "<ul>\n";
                        #<!-- no content in item -->\n";
                    }
                }
                # are there only prinable chars? We default to unordered
                elsif ($expansion =~ /[[:alnum:][:punct:]]+/) {
                    $parser->{+P . 'list'}->[$lvl]->{type} = 'ul';
                    print $out_fh '<ul>' . "\n";
                    # do nothing
                }
                # The lists text may be in a normal text section...
                # we default to unordered
                else {
                    $parser->{+P . 'list'}->[$lvl]->{type} = 'ul';
                    $parser->{+P . 'list'}->[$lvl]->{contentInCmd} = 0;
                    print $out_fh "<ul>\n";
                }
            }

            # if it is not the first item we save the checks for list-type
            else {

                # but first we need to close the last item!
                if ($parser->{+P . 'listjustwentback'}) {
                    $parser->{+P . 'listjustwentback'} = 0;
                }
                else {
                    # we need to close the last item!
                    print $out_fh '</li>' . "\n";
                }

                my $type =
                   $parser->{+P . 'list'}->[$lvl]->{type};

                # then we check the type and extract the content
                if ($type eq 'ol') {
                    if ($expansion =~ /^\s*\d+\s*(.*)$/) {
                        $expansion = $1;
                    }
                }
                if ($type eq 'ul') {
                    if ($expansion =~ /^\s*\*{1}\s*(.*)$/) {
                        $expansion = $1;
                    }
                }
            }

            # we print the item... but we don't close it!
            # it get's closed by the next item or the =back call
            print $out_fh '<li>' . $expansion;
        }
    }
}

# Overwrite sub of Pod::Parser
# Here all code parts of POD get parsed
sub verbatim { 
    my ($parser, $paragraph, $line_num) = @_; 
    my $out_fh = $parser->output_handle();       # handle for parsing output

    # We have to escape the case where there is only a newline, because
    # Pod::Parser calls verbatim() with $paragraph="\n" every time an empty
    # line is found in the Pod. But that is not what we are looking for!
    # We are looking for code-blocks here...
    if ($paragraph eq "\n") { return }

    # we look for POD inline commands
    my $expansion = $parser->interpolate($paragraph, $line_num);
    # then for special chars
    $expansion = _html_enc($expansion);
    # and last but not least we replace whitespace with a HTML tag.
    # this we do only for the verbatim command!
    # this is so, that code format (indenting) is keeped in html
    $expansion = _nbsp($expansion);

    # also only in verbatim we replace newline with the <br /> tag
    # this is so, that code format is keeped in html
    $expansion =~ s/\n/<br \/>\n/g;

    # trim must be last,
    # otherwise _nbsp() is not working for the first line
    trim $expansion;

    # ok, we are done and print out the result
    print $out_fh "<code>$expansion</code>\n";
}

# Overwrite sub of Pod::Parser
# Here normal POD text paragraphs get parsed
sub textblock { 
    my ($parser, $paragraph, $line_num) = @_; 
    my $out_fh = $parser->output_handle();       # handle for parsing output

    # we could be in a =begin block so we just check that and return if
    # this is the case
    if ($parser->{+P . 'begin'} eq 'html') {
        # we are in a html block, so just print the plain thing
        print $out_fh "<p>\n";
        print $out_fh $paragraph;
        print $out_fh "</p>\n";
        return
    }

    # no begin block... so do the rest of this complicate code!

    # ok, this one is tricky...
    # textblock() can be called when the parser is actually parsing a list.
    # this happens if the list is written like that:
    # =over
    #
    # =item
    #
    # Text that appears in this sub as $paragraph
    #
    # =back
    # If the text is on the SAME LINE as the =item command, this will not
    # happen. It is only when the text is separated with newline.
    # Ok... we need to check here if we are in a list.. and then do some
    # stuffe to handle that case.

    # we translate the POD inline commands...
    my $expansion = $parser->interpolate($paragraph, $line_num);
    # remove leading and trailing whitespace...
    trim $expansion;
    # and translate special chars to HTML
    $expansion = _html_enc($expansion);

    # store the list-nesting in a local variable (just for readability)
    my $lvl = $parser->{+P . 'listlvl'};

    # if there is no list WE ARE LUCKY and just print the text as paragraph
    if (not exists $parser->{+P . 'list'}) {
        print $out_fh '<p>' . $expansion . '</p>' . "\n";
    }
    # NOOOOOOO... we have a list
    # ok... let's try to figure out what to do!

    # items and some content found already in the command...
    # ... so we add a <br /> before the following textblock.
    elsif ($parser->{+P . 'list'}->[$lvl]->{items} > 0
           and $parser->{+P . 'list'}->[$lvl]->{contentInCmd} == 1
           ) {
        print $out_fh '<br />' . $expansion;
    }
    # if there was not yet content found we just print what we have now
    elsif ($parser->{+P . 'list'}->[$lvl]->{items} > 0) {
        print $out_fh $expansion;
    }
    # if there where no items yet this can only mean that we are in a list
    # without any items but with pure text... so we do blockquotes for
    # each paragraph
    elsif ($parser->{+P . 'list'}->[$lvl]->{items} == 0) {

        # we set the listtype
        $parser->{+P . 'list'}->[$lvl]->{type} = 'blockquote';
        $parser->{+P . 'list'}->[$lvl]->{blockquotes}++;

        if ($parser->{+P . 'list'}->[$lvl]->{blockquotes} == 1
            and $lvl > 0
            and $parser->{+P . 'list'}->[$lvl-1]->{items} > 0
            ) {
            print $out_fh "</li>\n";
        }

        # we do some pseudo-indenting
        # TODO: more nice would be real nesting...
        for (0..$lvl) {
            print $out_fh '<blockquote>';
        }
        print $out_fh $expansion;
        for (0..$lvl) {
            print $out_fh '</blockquote>' ."\n";
        }
    }
    else {
        # we should not reach here...
        croak "POD parsing error. Found undefined textblock in a list.";
    }
}

# Overwrite sub of Pod::Parser
# This method is called for handling inline POD, like e.g. B<some text>
sub interior_sequence {
    my ($parser, $cmd, $arg) = @_;

    # IMPORTANT here we do some tricky stuff...
    # what we actually want is this:
    #     B<some text>   ->   <b>some text</b>
    # but this is not possible, because then the <> would be replaced by
    # HTML entities later on!
    # So that is why we replace like this:
    #     <   ->   constant: LT
    # and
    #     >   ->   constant: GT
    # So B<some text> becomes XLTXsome textXGTX
    # The function which is doing the HTML translation must then replace
    # this words again with < and > (this is what _html_enc() is doing)
    return LT . 'b'    . GT . $arg . LT . '/b'    . GT  if ($cmd eq 'B');
    return LT . 'code' . GT . $arg . LT . '/code' . GT  if ($cmd eq 'C');
    return LT . 'code' . GT . $arg . LT . '/code' . GT  if ($cmd eq 'F');
    return LT . 'i'    . GT . $arg . LT . '/i'    . GT  if ($cmd eq 'I');
    return              AMP . $arg . COL                if ($cmd eq 'E');

    # if there is an L<> we have to take care a little bit more
    if ($cmd eq 'L') {

        # if we have this:
        #     L<CHI::Driver::File|File>
        # this means that CHI::Driver::File is the name to be displayed
        # and "File" is the link... which we direct to metacpan...

        # empty vars
        my $text = '';
        my $link = '';

        # if named we set the vars
        if ($arg =~ m/^(.*)\|(.*)$/) {
            $text = $1;
            $link = $2;
        }

        # in case this is not set, we set it to original value
        $link = $arg unless $link;

        # the case
        #     L</chapter>
        # for relative sections is not handled well here because we
        # don't know the module like that!
        # so we just print the text as is
        if($link =~ m%^/(.*)%) {
            my $section = $1;
            if ($text) {
                return "$text ($section)";
            }
            else {
                return DQUO . $section . DQUO;
            }
            # EXIT
        }

        # if the links seems to be http we also just return!
        elsif ($link =~ /^http.*$/
            or $link =~ /^.*\.{1}\w{2,5}$/ ) {
                # this is a weblink!
                # keep on going...
        }

        # if no special case we continue...
        elsif ($link =~ m%(.*)/(.*)%) {
            my $module  = $1;
            my $section = $2;
            $section =~ s/"//;

            if ($module && $section) {
                $link = "$module#$section";
            }
            elsif ($module && not $section) {
                $link = $module;
            }
            elsif (not $module && $section) {
                # this case should not happen but you never know
                # (it should be handled in the first if!)
                return "\"$section\"";
            }

            # this URL should be valid now
            $link = "https://metacpan.org/module/$link";

        }
        # normal module name
        else {
            # this URL should be valid now
            $link = "https://metacpan.org/module/$link";
        }

        # in case this is not set, we set it to original value
        $text = $arg unless $text;

        return LT.'a href='.QUO.$link.QUO.GT.$text.LT.'/a'.GT
    }

    # if nothing matches we return the content unformated 'as is'
    return $arg;
}

sub parse {
    my ($parser, $input) = @_;

    # INPUT:
    my $input_fh = IO::String->new($input);

    # OUTPUT:
    # We create this IO-object because Pod::Parser does not provide
    # pure string-data as return of result data
    my $buffer4html; # this variable will contain the result!!!
    my $buffer4html_handle = IO::String->new($buffer4html);

    # we call the parser to parse, result will be in $buffer4html
    $parser->parse_from_filehandle($input_fh, $buffer4html_handle);

    return $buffer4html;
};

sub set_options {
    my $self = shift;
    my $args = shift;

    if (ref($args) eq "HASH") {
        $self->head0_mode($args->{head0_mode}) if (exists $args->{head0_mode});
        $self->pagemode  ($args->{pagemode})   if (exists $args->{pagemode});
    }
    else {
        $self->debug_msg('Plugin options are not in a HASH');
    }
}

sub pagemode {
    my ($self, $boolean) = @_; 

    if (@_ > 1) {
        $self->{+P . 'pages'} = $boolean;
    }   
    else {
        return $self->{+P . 'pages'};
    }   
}

sub head0_mode {
    my ($self, $boolean) = @_; 

    if (@_ > 1) {
        $self->{+P . 'head0_mode'} = $boolean;
    }   
    else {
        return $self->{+P . 'head0_mode'};
    }   
}

# encode_entities() from HTML::Entities does not translate it correctly
# this is why I make it here manually as a quick fix
# don't reall know where how to handle this utf8 problem for now...
sub _html_enc {
    my $string = shift;

    $string = encode_entities($string);
                            #    ^
    my $lt = LT;            #    |
    my $gt = GT;            #    |
    my $am = AMP;           #    |
    my $co = COL;           #    |-- don't change this order!
    my $qu = QUO;           #    |
    my $dqu= DQUO;          #    |
    $string =~ s/$lt/</g;   #    |
    $string =~ s/$gt/>/g;   #    |
    $string =~ s/$am/&/g;   #    |
    $string =~ s/$co/;/g;   #    |
    $string =~ s/$qu/'/g;   #    |
    $string =~ s/$dqu/"/g;  #<---|

    return $string;
}

## replaces whitespace with html entitie
sub _nbsp {
    my $string = shift;

    $string =~ s/\ /&nbsp;/g;

    return $string;
}

1;

__END__

=encoding utf8

=head1 NAME

EBook::MOBI::Driver::POD - Create HTML, flavoured for the MOBI format, out of POD.

This module extends L<Pod::Parser> for parsing capabilities. The module L<HTML::Entities> is used to translate chars to HTML entities.

=head1 SYNOPSIS (for users)

The plugin is called like this while using C<EBook::MOBI>:

 use EBook::MOBI;
 my $book = EBook::MOBI->new();

 my $POD_in = <<END;
 =head1 SOME POD

 Just an example.
 Normal text is easy.
 Some specials following now...

 =for image /path/to/camel.jpg This is a nice animal.

 =begin html

 <p>Some <i>HTML</i> junks.</p>

 =end html

 END

 $book->add_content( data           => $POD_in,
                     driver         => 'EBook::MOBI::Driver::POD',
                     driver_options => { pagemode => 1, head0_mode => 0 }
                   );


=head1 SYNOPSIS (for developers)

This module is a plugin for L<EBook::MOBI>.
You probably don't need to access this module directly, unless you are a developer for C<EBook::MOBI>.

 use EBook::MOBI::Driver::POD;
 my $plugin = new EBook::MOBI::Driver::POD;

 my $mobi_format = $plugin->parse($pod);

=head1 METHODS

=head2 parse

This is the method each plugin should provide!
It takes the input format as a string and returns MHTML.

=head1 OPTIONS (POD plugin specific)

=head2 set_options

This method is provided by all plugins.
This module supports the following options:

 $plugin->set_options(pagemode => 1, head0_mode => 1);

See description below for more details of the options.

=head3 pagemode

Pass any true value to enable C<pagemode>. The effect will be, that before every - but the first - title on highest level there will be a pagebreak inserted. This means: The resulting ebook will start each C<h1> chapter at a new page.

Default is to not add any pagebreak.

=head3 head0_mode

Pass any true value to enable C<head0_mode>. The effect will be, that you are allowed to use a C<=head0> command in your POD.

Pod can now look like this:

  =head0 Module EBook::MOBI
  
  =head1 NAME

  =head1 SYNOPSIS

  =head0 Module EBook::MOBI::Converter

  =head1 NAME

  =head1 SYNOPSIS

  =cut

This feature is useful if you want to have the documentation of several modules in Perl in one ebook. You then can add a higher level of titles, so that the TOC does not only contain several NAME and SYNOPSIS entries.

Default is to ignore any C<=head0> command.

B<Note:> C<=head0> is not part of the official POD standard. You will create invalid POD if you use this syntax. However I find it usefull for processing existing docs. You have been warned.

=head1 SPECIAL SYNTAX FOR IMAGES

POD does not support images.
However you can add images with some special markup.

 =for image /path/to/image.jpg And some description here.

B<Note:> This version marks the old style of adding images as B<DEPRECATED>.
Please DON'T use this markup anymore:

 # DEPRECATED, will not be supported in next version
 =image /path/to/image.jpg And some description here.

=head1 EMPEDDING HTML IN YOUR POD

This module can detect HTML in your POD.
It will directly put it "as is" into the MOBI format, which should always work fine for simple stuff.
You have to use C<=begin> and C<=end> commands to mark your HTML recognisable.
C<=for> is not supported.

 =begin html
 
 <p>Some stuff in <i>HTML</i>...</p>

 =end html

=head1 COPYRIGHT & LICENSE

Copyright 2012, 2013 Boris Däppen, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms of Artistic License 2.0.

=head1 AUTHOR

Boris Däppen E<lt>bdaeppen.perl@gmail.comE<gt>

=cut
