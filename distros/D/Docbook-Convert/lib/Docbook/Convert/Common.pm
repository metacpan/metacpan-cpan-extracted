#
#  This file is part of Docbook::Convert.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#


#
#
package Docbook::Convert::Common;


#  Pragma
#
use strict qw(vars);
use vars   qw($VERSION);
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use Docbook::Convert::Constant;
use Docbook::Convert::Util;
use Data::Dumper;


#  Inherit Base functions (find_node etc.)
#
use base Docbook::Convert::Base;


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='1.012';


#  Make synonyms
#
&Docbook::Convert::Base::create_tag_synonym($ALL_TAG_SYNONYM_HR);


#===================================================================================================


sub _data {
    my ($self, $data_ar)=@_;
    return $data_ar;
}


sub _image_build {

    #  Build image output
    #
    my ($self, $data_ar)=@_;


    #  Get alt text, title, URL etc/
    my $alt_text1=$self->pull_node_tag_text($data_ar, 'alt', $NULL);
    my $title=$self->pull_node_tag_text($data_ar, 'title|caption|screeninfo', $NULL);
    my $image_data_ar=$self->find_node($data_ar, 'imagedata');
    my $image_data_attr_hr=$image_data_ar->[0][$ATTR_IX];
    my $alt_text2=$image_data_attr_hr->{'annotations'};
    my $alt_text=$alt_text1 || $alt_text2;
    my $url=$image_data_attr_hr->{'fileref'};


    #  Generation Options
    #
    my ($no_html, $no_image_fetch)=@{$self}{qw(no_html no_image_fetch)};


    #  Fetch image to calc width etc. if needed
    #
    if ((my $scale=$image_data_attr_hr->{'scale'}) && !$no_html && !$no_image_fetch) {

        #  Get Image width
        #
        my $width=$self->image_getwidth($url);
        $width *= ($scale/100);
        $image_data_attr_hr->{'width'}=$width;
    }

    #  Return output
    #
    return $self->_image($url, $alt_text, $title, $image_data_attr_hr);
}


sub _meta {
    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $SP);
    my $key=$data_ar->[$NODE_IX];
    $self->{'_meta'}{$key}=$text;
    return undef;
}


sub appendix {

    my ($self, $data_ar)=@_;
    delete @{$self}{qw(_sect1 _sect2 _sect3 _sect4)};
    my $app_ix=$self->{'_appendix_count'}++;
    my @label;
    my $cr=sub {
        my ($cr, $num)=@_;
        my $int;
        if ($int=int($num/26)) {
            $cr->($cr, ($int-1));
        }
        push @label, chr(($num % 26)+65);
    };
    $cr->($cr, $app_ix);
    my $label=join(undef, @label);
    my ($title, $subtitle)=
        $self->pull_node_tag_text($data_ar, 'title|subtitle', $NULL);
    my $text=$self->pull_node_text($data_ar, $CR2);
    my $appendix=$self->_h1("Appendix $label: $title");
    return join($CR2, $appendix, $text);

}


sub arg {

    my ($self, $data_ar)=@_;

    #my $text=$self->pull_node_text($data_ar, $SP);
    my $text=$self->pull_node_text($data_ar, $NULL);
    my $attr_hr=$data_ar->[$ATTR_IX] && $data_ar->[$ATTR_IX];
    if ((my $choice=$attr_hr->{'choice'}) eq 'req') {
        $text="{$text}";
    }
    elsif ($choice eq 'plain') {

        #  Do nothing
        #
    }
    else {
        #  Choice is default - "opt"
        $text="[$text]";
    }
    if ($attr_hr->{'rep'} eq 'repeat') {
        $text.='...';
    }
    return $self->_code($text);
}


sub article {

    my ($self, $data_ar)=@_;

    #  Rendering an article. Get article body
    #
    my @text=@{$self->pull_node_text($data_ar)};


    #  Title
    #
    my $meta_title=$self->find_node_tag_text($data_ar, 'title', $NULL);
    $self->{'_meta'}{'title'}=$meta_title;


    #  Any prefix/suffix to be appended (e.g. =pod, =cut for POD);
    my ($prefix, $suffix)=map {$self->$_()} qw(_prefix _suffix);


    #  Shortcut any relevent params we will need
    #
    my (
        $meta_display_top, $meta_display_bottom, $meta_display_title,
        $meta_display_title_h_style
        )
        =@{$self}{qw(
            meta_display_top
            meta_display_bottom
            meta_display_title
            meta_display_title_h_style
        )};


    #  Do we want to display meta data - if so format and spit out
    #
    if ($meta_display_top || $meta_display_bottom) {


        #  Generate title if requested
        #
        if ($meta_display_title) {
            if (my $h_style="_${meta_display_title_h_style}") {
                $meta_display_title=$self->$h_style($meta_display_title);
            }
        }

        #  Gather key: value meta data tags
        #
        my @meta;
        foreach my $key ('title', @{$ALL_TAG_SYNONYM_HR->{'_meta'}}) {
            if (my $value=$self->{'_meta'}{$key}) {
                my $meta_key=ucfirst($key);
                push @meta, "$meta_key: $value";
            }
        }
        my $meta=join($CR, @meta);


        #  Output at top or bottom as required
        #
        if ($meta_display_top) {
            return $self->_text_cleanup(
                join($CR2, grep {$_} $prefix, $meta_display_title, $meta, @text, $suffix));
        }
        if ($meta_display_bottom) {
            return $self->_text_cleanup(
                join($CR2, grep {$_} $prefix, @text, $meta_display_title, $meta, $suffix));
        }

    }
    else {
        return $self->_text_cleanup(
            join($CR2, grep {$_} $prefix, @text, $suffix));
    }
}


sub blockquote {
    my ($self, $data_ar)=@_;
    my @text=@{$self->pull_node_text($data_ar)};
    my $text;
    foreach my $line (@text) {
        my @line=($line=~/^(.*)$/gm);
        foreach my $line (@line) {
            chomp($line);
            $text.="> ${line}${CR}";
        }
        $text.=">${CR}";
    }
    return $text;
}


sub citetitle {
    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $NULL);
    return $self->_italic($text);
}


sub cmdsynopsis {
    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $SP);
    return $self->_code($text);
}


sub command {
    my ($self, $data_ar)=@_;
    if ($self->find_parent($data_ar, 'screen|programlisting')) {

        #  render later
        return $data_ar;
    }
    else {
        my $text=$self->pull_node_text($data_ar, $NULL);
        return $self->_code($text);
    }
}


sub code {
    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $NULL);
    return $self->_code($text);
}


sub email {
    my ($self, $data_ar)=@_;
    my $email=$self->pull_node_text($data_ar, $NULL);
    return $self->_email($email);
}


sub _null {
    my ($self, $data_ar)=@_;
    return undef;
}


sub _sect {
    my ($self, $data_ar, $count, $h_level)=@_;
    my ($md_section_num)=$self->{'md_section_num'};

    my ($title, $subtitle)=
        $self->pull_node_tag_text($data_ar, 'title|subtitle', $NULL);
    debug("title: $title, subtitle: $subtitle");
    my $text=$self->pull_node_text($data_ar, $CR2);
    debug("text $text");
    my $tag=$data_ar->[$NODE_IX];
    $h_level ||= 1;

    #my ($h_level)=($tag=~/(\d+)$/) || 1;
    $h_level="_h${h_level}";

    #return join($CR2, grep {$_} $self->$h_level("$count $title"), $text);
    if ($md_section_num) {
        return join($CR2, grep {$_} $self->$h_level("${count}. $title"), $text);
    }
    else {
        return join($CR2, grep {$_} $self->$h_level($title), $text);
    }
}


sub emphasis {
    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $NULL);
    my $attr_hr=$data_ar->[$ATTR_IX];
    my $role=$attr_hr->{'role'};
    if (($role eq 'bold') || ($role eq 'strong')) {
        return $self->_bold($text);
    }
    elsif ($role eq 'strikethrough') {
        return $self->_strikethrough($text);
    }
    else {
        return $self->_italic($text);
    }
}


sub figure {
    my ($self, $data_ar)=@_;
    return $self->_image_build($data_ar);
}


sub group {

    my ($self, $data_ar)=@_;
    my ($text_ar)=$self->pull_node_text($data_ar);
    my $text=join(' | ', @{$text_ar});
    $text="[ $text ]" if (@{$text_ar} > 1);
    return $text;

}


sub itemizedlist {
    my ($self, $data_ar)=@_;
    my @list;
    foreach my $text (@{$self->pull_node_text($data_ar)}) {
        push @list, $self->_list_item("* $text");
    }

    #return join($CR2, grep {$_} $self->_list_begin(), @list, $self->_list_end);
    return join($CR2, $self->_list_begin(), @list, $self->_list_end);
}


sub link {
    my ($self, $data_ar)=@_;
    my $attr_hr=$data_ar->[$ATTR_IX];
    my $url;
    my $title=$attr_hr->{'annotations'};
    my $text=$self->pull_node_text($data_ar, $NULL);
    if ($attr_hr->{'xlink:href'}) {
        $url=$attr_hr->{'xlink:href'};
    }
    elsif ($attr_hr->{'xl:href'}) {
        $url=$attr_hr->{'xl:href'};
    }
    elsif (my $linkend=$attr_hr->{'linkend'}) {
        $url="#${linkend}";

        #$text ||= $SP . $linkend;
        $text ||= $linkend;
    }
    debug("link $title, $url");

    #$text ||= $SP . $url;
    $text ||= $url;
    return $self->_link($url, $text, $title);
}


sub listitem {
    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $self->_listitem_join());
    return $text;
}


sub mediaobject {
    my ($self, $data_ar)=@_;

    #if ($self->find_parent($data_ar, 'figure')) {
    #  Are we delaying render ?
    if ($self->find_parent($data_ar, $MEDIAOBJECT_DELAY_RENDER_AR)) {

        #  render later
        return $data_ar;
    }
    else {
        return $self->_image_build($data_ar);
    }
}


sub orderedlist {
    my ($self, $data_ar)=@_;
    my (@list, $count);
    foreach my $text (@{$self->pull_node_text($data_ar)}) {
        $count++;
        push @list, $self->_list_item("$count. $text");
    }

    #return join($CR2, grep {$_} $self->_list_begin(), @list, $self->_list_end);
    return join($CR2, $self->_list_begin(), @list, $self->_list_end);
}


sub para {

    my ($self, $data_ar)=@_;

    #my $text=$self->pull_node_text($data_ar, $NULL);
    my $text=$self->pull_node_text($data_ar, $SP);
    return $text;

}


sub thead {

    my ($self, $data_ar)=@_;
    my @row;
    foreach my $row_ar (@{$self->find_node($data_ar, 'row')}) {
        foreach my $entry_ar (@{$self->find_node($row_ar, 'entry')}) {

            #print "thead entry_ar: $entry_ar\n";
            my $text=$self->pull_node_text($entry_ar, $NULL);
            $text=$self->text_wrap($text);
            push @row, $self->_bold($text);
        }
        $self->{'_table'}{'thead'}=\@row;
        last;
    }
    return undef;

}


sub tbody {

    my ($self, $data_ar)=@_;
    foreach my $row_ar (@{$self->find_node($data_ar, 'row')}) {
        my @row;
        foreach my $entry_ar (@{$self->find_node($row_ar, 'entry')}) {
            my $text=$self->pull_node_text($entry_ar, $NULL);
            $text=$self->text_wrap($text);
            push @row, $text;
        }
        push @{$self->{'_table'}{'tbody'}}, \@row;

        #push @{$self->{'_table'}{'tbody'}},[map { undef } @row]
    }
    return undef;

}


sub table {

    my ($self, $data_ar)=@_;
    my $title=$self->pull_node_tag_text($data_ar, 'title', $NULL);
    my $thead_ar=$self->{'_table'}{'thead'};
    use Text::Table;

    #my $table_or=Text::Table->new((map {\"|", $_} @{$thead_ar}), \"|");
    my $table_or=Text::Table->new((map {\'|', $_} @{$thead_ar}), \'|');

    my $tbody_ar=$self->{'_table'}{'tbody'};
    foreach my $row_ar (@{$tbody_ar}) {
        $table_or->load($row_ar);
    }

    my @table;
    push @table, $table_or->rule('-', '-');
    push @table, $table_or->title();
    push @table, $table_or->rule('-', '-');
    my @row=$table_or->table();
    foreach my $row (1..$#row) {
        push @table, $row[$row];

        #push @table, $table_or->body_rule(' ', ' ') unless ($_ == $#row);
    }
    push @table, $table_or->body_rule('-', '-');

    #print $self->_code($table_or->stringify());
    #my $table=$table_or->stringify();
    return $title . $CR2 . join(undef, map {"${SP4}$_"} @table) . $CR2;

    #return $self->_code($table_or->stringify());

}


sub procedure {

    my ($self, $data_ar)=@_;
    my $title=$self->pull_node_tag_text($data_ar, 'title', $NULL);
    my @step;
    my $count;
    foreach my $ar (@{$self->find_node($data_ar, 'step')}) {
        $count++;
        my $text=$self->pull_node_text($ar, $NULL);
        push @step, "${count}\\. ${text}";
    }
    return join($CR2, $self->_bold($title), @step);

}


sub programlisting {
    my ($self, $data_ar)=@_;
    my $attr_hr=$data_ar->[$ATTR_IX];
    my $lang=$attr_hr->{'language'};
    my $text=$self->pull_node_text($data_ar, $NULL);
    $text="${CR2}```${lang}${CR}${text}${CR}```${CR2}";
    return $text
}


sub menuchoice {

    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, ' > ');
    return $self->_bold($text);

}


sub qandadiv {

    my ($self, $data_ar)=@_;
    my $title=$self->pull_node_tag_text($data_ar, 'title', $NULL);
    my $text=$self->pull_node_text($data_ar, $CR2);
    return join($CR2, $self->_h2($title), $text);

}


sub question {

    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $CR2);
    return $self->_bold('Q:') . $SP . $text;

}


sub answer {

    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $CR2);
    return $self->_bold('A:') . $SP . $text;

}


sub quote {

    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $NULL);
    return qq{\"$text\"};
}


sub refmeta {
    my ($self,          $data_ar)=@_;
    my ($refentrytitle, $manvolnum)=
        $self->find_node_tag_text($data_ar, 'refentrytitle|manvolnum', $NULL);
    my $text=$self->_h1("${refentrytitle}(${manvolnum})");
    return $text;
}


sub refnamediv {

    my ($self,    $data_ar)=@_;
    my ($refname, $refpurpose)=
        $self->find_node_tag_text($data_ar, 'refname|refpurpose', $NULL);
    my $heading=$REFENTRY_TEXT_HR->{'name'};
    my $text=$self->_h1($heading) . $CR2 . join(' - ', grep {$_} $refname, $refpurpose);
    return $text;
}


sub refsection {
    my ($self,  $data_ar)=@_;
    my ($title, $subtitle)=
        $self->pull_node_tag_text($data_ar, 'title|subtitle', $NULL);
    my $text=$self->pull_node_text($data_ar, $CR2);
    return join($CR2, $self->_h1($title), $text);
}


sub refsynopsisdiv {
    my ($self, $data_ar)=@_;

    #my $text=$self->pull_node_text($data_ar, $NULL);
    my $text=$self->pull_node_text($data_ar, $CR2);
    my $heading=$REFENTRY_TEXT_HR->{'synopsis'};
    $text=$self->_h1($heading) . $CR2 . $text;
    return $text;
}


sub sbr {
    my ($self, $data_ar)=@_;

    #  This gets cleaned up by the _code routine
    return "<**SBR**>";
}


sub screen {
    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $NULL);
    my @text=($text=~/^(.*)$/gm);
    return $CR2 . join($CR, map {"${SP4}$_"} @text) . $CR2;
}


sub sect1 {
    my ($self, $data_ar)=@_;

    #  Are we nested ?
    #
    my $count=1;
    my $cr=sub {
        my ($cr, $data_ar)=@_;
        if (my $prnt_data_ar=$self->find_parent($data_ar, 'section')) {
            $count++;
            $cr->($cr, $prnt_data_ar);
        }
        else {
            return undef;
        }
    };
    $cr->($cr, $data_ar);

    #  If count > 1 then yes, pretend we are sect2, sect3 etc/
    if ($count > 1) {
        my $sect="sect${count}";
        return $self->$sect($data_ar);
    }
    else {
        #  Not nested
        my $count_sect1=++$self->{'_sect1'};
        delete @{$self}{qw(_sect2 _sect3 _sect4)};
        return $self->_sect($data_ar, $count_sect1, 1);
    }
}


sub sect2 {
    my ($self, $data_ar)=@_;
    my $count_sect1=($self->{'_sect1'}+1);
    my $count_sect2=++$self->{'_sect2'};
    delete @{$self}{qw(_sect3 _sect4)};
    my $count="$count_sect1.$count_sect2";
    return $self->_sect($data_ar, $count, 2);
}


sub sect3 {
    my ($self, $data_ar)=@_;
    my $count_sect1=($self->{'_sect1'}+1);
    my $count_sect2=($self->{'_sect2'}+1);
    my $count_sect3=++$self->{'_sect3'};
    delete @{$self}{qw(_sect4)};
    my $count="$count_sect1.$count_sect2.$count_sect3";
    return $self->_sect($data_ar, $count, 3);
}


sub sect4 {
    my ($self, $data_ar)=@_;
    my $count_sect1=($self->{'_sect1'}+1);
    my $count_sect2=($self->{'_sect2'}+1);
    my $count_sect3=($self->{'_sect3'}+1);
    my $count_sect4=++$self->{'_sect4'};
    my $count="$count_sect1.$count_sect2.$count_sect3.$count_sect4";
    return $self->_sect($data_ar, $count, 4);
}


sub _text {
    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $CR2);

    #  Clean up and extra blank lines
    $text=~s/^(\s*${CR}){2,}/${CR}/gm;
    return $text;
}


sub term {
    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $NULL);

    #return $self->_bold($self->_code($text));
    return $self->_bold($text);
}


sub ulink {
    my ($self, $data_ar)=@_;
    my $attr_hr=$data_ar->[$ATTR_IX];
    my $url=$attr_hr->{'url'};
    my $text=$self->pull_node_text($data_ar, $NULL);
    return $self->_link($url, $text);
}


sub uri {
    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $NULL);
    return $SP . "<${text}>";
}


sub variablelist {
    my ($self, $data_ar)=@_;
    my @list;
    foreach my $ar (@{$self->find_node($data_ar, 'varlistentry')}) {
        my $text=$self->pull_node_text($ar, $self->_variablelist_join());
        push @list, $self->_list_item("* $text");
    }

    #return join($CR2, grep {$_} $self->_list_begin(), @list, $self->_list_end);
    return join($CR2, $self->_list_begin(), @list, $self->_list_end);
}


sub warning {    # synonym for caution, important, note, tip
    my ($self, $data_ar)=@_;
    my $tag=$data_ar->[$NODE_IX];
    my $text=$self->pull_node_text($data_ar, $NULL);
    $tag=lc($tag);
    my $admonition=$self->_bold($ADMONITION_TEXT_HR->{$tag});
    return $CR2 . "$admonition: $text";
}


sub footnote {
    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $NULL);
    push @{$self->{'footnote'}}, $text;
    return undef;
}


sub xref0 {
    my ($self, $data_ar)=@_;
    my $attr_hr=$data_ar->[$ATTR_IX];
    if (my $linkend=$attr_hr->{'linkend'}) {

        #  Don't link at the moment
        return $self->_italic($linkend);
    }
    else {
        return undef;
    }
}


sub _text_cleanup {

    my ($self, $text)=@_;
    $text=~s/^(\s*${CR}){2,}/${CR}/gm;
    return $text;

}


1;
__END__

=begin markdown

# NAME

Docbook::Convert::Common - shared DocBook element handlers

# DESCRIPTION

This internal class implements element handlers shared by the custom output
renderers. It converts common structural, inline, list, table, image and link
elements after `Docbook::Convert` has parsed the source document.

There is no supported application API in this module. Use
`Docbook::Convert` or `Docbook::Convert::Pandoc`.

# SEE ALSO

`Docbook::Convert`, `Docbook::Convert::Markdown`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of Docbook::Convert.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 NAME

Docbook::Convert::Common - shared DocBook element handlers


=head1 DESCRIPTION

This internal class implements element handlers shared by the custom output
renderers. It converts common structural, inline, list, table, image and link
elements after C<Docbook::Convert> has parsed the source document.

There is no supported application API in this module. Use
C<Docbook::Convert> or C<Docbook::Convert::Pandoc>.


=head1 SEE ALSO

C<Docbook::Convert>, C<Docbook::Convert::Markdown>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=cut
