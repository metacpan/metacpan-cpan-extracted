package DocSet::Source::POD;

use strict;
use warnings;

use DocSet::Util;
use DocSet::RunTime;

use vars qw(@ISA);
require DocSet::Doc;
@ISA = qw(DocSet::Doc);

use constant HEAD_MAX_LEVEL => 4;
use constant MAX_DESC_LENGTH => 500;

# META: we are presenting too early, or this code should be moved to
# POD2HTML specific module
require Pod::POM::View::HTML;
my $mode = 'Pod::POM::View::HTML';

sub retrieve_meta_data {
    my ($self) = @_;

    $self->parse_pod;

    #print Pod::POM::View::HTML->print($pom);

    my $meta = {
        title => 'No Title',
        abstract => '',
    };

    my $pom = $self->{parsed_tree};
    my @sections = $pom->head1();

    
    if (@sections) {

        # extract the title from the NAME section and remove it from content
        if ($sections[0]->title =~ /NAME/) {
            # don't present on purpose ->present($mode); there should
            # be no markup in NAME a problem with
            # <TITLE><CODE>....</CODE><TITLE> and alike
            $meta->{title} = (shift @sections)->content();
            $meta->{title} =~ s/^\s*|\s*$//sg;
        }

        # stitle is the same in docs
        $meta->{stitle} = $meta->{title};

        # locate the DESCRIPTION section (should be in the first three
        # sections)
        for (0..2) {
            next unless defined $sections[$_]
                && $sections[$_]->title =~ /DESCRIPTION/i;

            my $abstract = $sections[$_]->content->present($mode);

# cannot do this now, as it might cut some markup in the middle: <i>1 2</i>
#            # we are interested only in the first paragraph, or if its
#            # too big first MAX_DESC_LENGTH chars.
#            my $index = index $abstract, " ", MAX_DESC_LENGTH;
#            # cut only if index didn't return '-1' which is when the the
#            # space wasn't found starting from location MAX_DESC_LENGTH
#            unless ($index == -1) {
#                $abstract = substr $abstract, 0, $index+1;
#                $abstract .= " ...&nbsp;<i>(continued)</i>";
#            }
#
#           # temp workaround, but can only split on paras
            $abstract =~ s|<p>(.*?)</p>.*|$1|s;

            $meta->{abstract} = $abstract;
            last;
        }
    }

    $meta->{link} = $self->{rel_dst_path};

    # put all the meta data under the same attribute
    $self->{meta} = $meta;

    # build the toc datastructure
    my @toc = ();
    my $level = 1;
    for my $node (@sections) {
        push @toc, $self->render_toc_level($node, $level);
    }
    $self->{toc} = \@toc;

}

sub render_toc_level {
    my ($self, $node, $level) = @_;
    my $title = $node->title;
    my $link = "$title";     # must stringify to get the raw string
    $link =~ s/^\s*|\s*$//g; # strip leading and closing spaces
    $link =~ s/\W/_/g;       # META: put into a sub? see Doc::Common::pod_pom_html_anchor
    # prepand '#' for internal links
    my $toc_link = "toc_$link"; # self referring toc entry
    $link = "#$link";

    my %toc_entry = (
        title    => $title->present($mode), # run the formatting if any
        link     => $link,
        toc_link => $toc_link,
    );

    my @sub = ();
    $level++;
    if ($level <= HEAD_MAX_LEVEL) {
        # if there are deeper than =head4 levels we don't go down (spec is 1-4)
        my $method = "head$level";
        for my $sub_node ($node->$method()) {
            push @sub, $self->render_toc_level($sub_node, $level);
        }
    }
    $toc_entry{subs} = \@sub if @sub;

    return \%toc_entry;
}



sub parse_pod {
    my ($self) = @_;
    
    # already parsed
    return if exists $self->{parsed_tree} && $self->{parsed_tree};

#    print ${ $self->{content} };

    use Pod::POM;
    my %options;
    my $parser = Pod::POM->new(\%options);
    my $pom = $parser->parse_text(${ $self->{content} })
        or die $parser->error();

    $self->{parsed_tree} = $pom;

    # examine any warnings raised
    if (my @warnings = $parser->warnings()) {
        print "\n", '-' x 40, "\n";
        print "File: $self->{src_path}\n";
        warn "$_\n" for @warnings;
    }
}

sub src_filter {
    my ($self) = @_;

    $self->extract_pod;

    $self->head2page_breaks() if $self->{docset}->options('slides_mode');

    $self->podify_items() if $self->{docset}->options('podify_items');
}

sub extract_pod {
    my ($self) = @_;

    my @pod = ();
    my $in_pod = 0;
    for (split /\n{2,}/, ${ $self->{content} }) {
        unless ($in_pod) {
            s/^[\s\n]*//ms; # skip empty lines in preamble
            $in_pod = /^=/s;
        }
        next unless $in_pod;
        $in_pod = 0 if /^=cut/;
        push @pod, $_;
    }

    # handle empty files
    unless (@pod) {
        push @pod, "=head1 NAME", "=head1 Not documented", "=cut";
    }

    my $content = join "\n\n", @pod;
    $self->{content} = \$content;
}

sub podify_items {
    my ($self) = @_;
  
    # tmp storage
    my @paras = ();
    my $items = 0;
    my $second = 0;

    # we want the source in paragraphs
    my @content = split /\n\n/, ${ $self->{content} };

    foreach (@content) {
        # is it an item?
        if (/^(\*|\d+)\s+((\*|\d+)\s+)?/) {
            $items++;
            if ($2) {
                $second++;
                s/^(\*|\d+)\s+//; # strip the first level shortcut
                s/^(\*|\d+)\s+/=item $1\n\n/; # do the second
                s/^/=over 4\n\n/ if $second == 1; # start 2nd level
            } else {
                # first time insert the =over pod tag
                s/^(\*|\d+)\s+/=item $1\n\n/; # start 1st level
                s/^/=over 4\n\n/ if $items == 1;
                s/^/=back\n\n/   if $second; # complete 2nd level
                $second = 0; # end 2nd level section
            }
            push @paras, split /\n\n/, $_;
        } else {
          # complete the =over =item =back tag
            $second=0, push @paras, "=back" if $second; # if 2nd level is not closed
            push @paras, "=back" if $items;
            push @paras, $_;
          # not a tag item
            $items = 0;
        }
    }

    my $content = join "\n\n", @paras;
    $self->{content} = \$content;

}


# add a page break for =headX in slides mode
sub head2page_breaks {
    my ($self) = @_;
  
    # we want the source in paragraphs
    my @content = split /\n\n/, ${ $self->{content} };

    my $count = 0;
    my @paras = ();
    foreach (@content) {
        # add a page break starting from the third head (since the
        # first is removed anyway, and we don't want to start a new
        # page on the very first page)
        if (/^=head/) {
            $count++;
            if ($count > 2) {
                push @paras, qq{=for html <?page-break>};
            }
        }
        push @paras, $_;
    }

    my $content = join "\n\n", @paras;
    $self->{content} = \$content;

}

1;
__END__

=head1 NAME

C<DocSet::Source::POD> - A class for parsing input document in the POD format

=head1 SYNOPSIS



=head1 DESCRIPTION

META: not sure if the customized implementation of L<> belongs
here. But it works as follows:

Assuming that the main I<config.cfg> specifies the following argument:

     dir => {
             ...
  
             # search path for pods, etc. must put more specific paths first!
             search_paths => [qw(
                 docs/2.0/api/mod_perl-2.0 
                 docs/2.0/api/ModPerl-Registry 
                 docs/2.0 
                 docs/1.0
                 .
             )],
  
             # what extensions to search for
             search_exts => [qw(pod pm html)],
  
 	    },	

Whenever the pod includes L<Title|foo::bar/section>, the code will
first convert C<foo::bar> into I<foo/bar> and then will try to find
the file I<foo/bar.pod> in the search path (similar to C<@INC>), as
well as files I<foo/bar.pm> and I<foo/bar.html> under dir I<src>. If
other C<search_exts> are specified they will be searched as well. If
there is a much the link will be created, otherwise only the title of
the link will be displayed.

Notice that the C<search_paths> must specify more specific paths
first. If you don't they won't be searched. Currently this is done
only to optimize memory usage and some speed, not sure if that's very
important. But this is different from how Perl does search with
C<@INC> since DocSet reads all the files in memory once and then
reuses this data.

=head2 METHODS

=over 

=item retrieve_meta_data()

=item parse_pod()

=item podify_items()

  podify_items();

Podify text to represent items in pod, e.g:

  1 Some text from item Item1
  
  2 Some text from item Item2

becomes:

  =over 4
 
  =item 1
 
  Some text from item Item1

  =item 2
 
  Some text from item Item2

  =back

podify_items() accepts 'C<*>' and digits as bullets

podify_items() receives a ref to array of paragraphs as a parameter
and modifies it. Nothing returned.

Moreover, you can use a second level of indentation. So you can have

  * title

  * * item

  * * item

or 

  * title

  * 1 item

  * 2 item

where the second mark is which tells whether to use a ball bullet or a
numbered item.

=item head2page_breaks

in the I<slides_mode> we want each =headX to start a new slide, so
this mode inserts the page-breaks:

  =for html <?page-break>

starting from the second header (well actually from the third in the
raw POD, because the first one (NAME) gets stripped before it's seen
by the rendering engine.

=back

=head1 AUTHORS

Stas Bekman E<lt>stas (at) stason.orgE<gt>

=cut
