package HTML::FormatNroff;

=head1 NAME

HTML::FormatNroff - Format HTML as nroff man page

=head1 SYNOPSIS

 require HTML::FormatNroff;
 $html = parse_htmlfile("test.html");
 $format_nroff = new HTML::FormatNroff(name => 'trial', 
                                       project => 'MyProject');
 print $formatter->format($html);

=head1 DESCRIPTION

The HTML::FormatNroff is a formatter that outputs nroff source
for the nroff text processor, using man macros, and tbl commands for table
processing.

The result of using the formatter must be processed as follows, when directing
output to the screen (assume output is in the file "text.nroff"):

    tbl -TX text.nroff | nroff -man | col

If the output is to be printed, on an laser printer for example, a command
similar to the following must be used:

    tbl -TX text.nroff | nroff -man -Tlj | lpr

Meta tags may be placed in the HTML so that portions of the HTML
will be ignored and not processed. Content between the tags

 <META NAME="nroff-control" CONTENT="ignore_start">
 <META NAME="nroff-control" CONTENT="ignore_end">

will be ignored. In the BODY META is not supported, but DIV may be used
as follows:

 <DIV TYPE="NROFF_IGNORE">
 </DIV>

In both the META and DIV uses, case is ignored.

=head1 METHODS

=cut

require 5.004;

require HTML::Formatter;
require HTML::FormatTableNroff;

@ISA = qw(HTML::Formatter);

use strict;

sub default_values
{
    (
     name => "",        # man page name
     section => 1,  # section of manual
     man_date => "",  # date for section
     project => "",     # name of project
     tables => [],
     fonts => [],
     current_table => undef,
     ignore => 0,
     man_header => 1, 
     page_width => "6",
     divs => [],
     );
}

=head2 $format_nroff->dt_start();

Start a definition term <DT>,
using a temporary indent and vertical space.

=cut

sub dt_start {
    my($self) = @_;

    $self->vspace(1);
    $self->textout("\n.ti +" . $self->{'lm'} . "\n "); 
    1;
}

=head2 $format_nroff->dd_start();

Start a data definition, <DD>, using a temporary indent.

=cut

sub dd_start {
    my($self) = @_;

    $self->adjust_lm(+6);
    $self->vspace(0);
    $self->textout("\n.ti +" . $self->{'lm'} . "\n "); 
    1;
}

=head2 $format_nroff->configure($arg);

Configure the nroff formatter, setting the attributes passed in the
$arg attribute (hash reference)

=cut

sub configure {
    my($self,$arg) = @_;

    my $key;
    foreach $key (keys %$arg) {
	$self->{$key} = $$arg{$key};
    }
    $self;
}

=head2 $format_nroff->begin();

Begin HTML formatting.

=cut

sub begin {
    my $self = shift;
    $self->HTML::Formatter::begin;
    $self->{lm} = 0;
}

=head2 $format_nroff->end();

End HTML formatting.

=cut

sub end {
    shift->collect("\n");
}

=head2 $format_nroff->html_start();

Process <HTML> start tag. Create the man page header based
on saved attributes, unless the attribute 
$format_nroff->{'man_header'} is not set. This generates the following header:

 .TH "name" section "date" "project"  

=cut

sub html_start {
    my $self = shift;

    if($self->{ignore}) { return 1; }

    unless($self->{man_header}) { return 1; }

    unless($self->{man_date}) {
	my($sec, $min, $hr, $mday, $mon, $year, $wday, $yday, $isdst) =
	    localtime();
	my $this_mon = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec')[$mon];
	$self->{man_date} = "$mday" . " $this_mon" . " $year";
    }

    $self->out(".TH \"" . $self->{name} . "\" \"" . $self->{section} .
	       "\" \"" .
	       $self->{man_date} .  "\" \"" . $self->{project} . "\"");
    1;
}

=head2 $format_nroff->font_start($font);

Start the font specified by the $font character (e.g. B, or I).
The font is remembered so nested fonts are handled correctly.

=cut

sub font_start {
    my($self, $font) = @_;

    push( @{ $self->{'fonts'} }, $font);

    $self->textout('\f' . "$font");    
}

=head2 $format_nroff->font_end();

End the current font, returning to the previous one.

=cut

sub font_end {
    my($self) = @_;

    pop( @{ $self->{'fonts'} });

    my $font = pop( @{ $self->{'fonts'} });
    push( @{ $self->{'fonts'} }, $font);

    unless($font) {
	$font = 'R';
    }
    $self->textout('\f' . "$font");    
}

=head2 $format_nroff->i_start();

Process <I> tag. 

=cut

sub i_start {
    my $self = shift;

    if($self->{ignore}) { return 1; }

    $self->font_start('I');
}

=head2 $format_nroff->i_end();

Process </I> tag. 

=cut

sub i_end {
    my $self = shift;

    if($self->{ignore}) { return 1; }

    $self->font_end();
}

=head2 $format_nroff->b_start();

Process <B> tag. 

=cut

sub b_start {
    my $self = shift;

    if($self->{ignore}) { return 1; }

    $self->font_start('B');
    1;
}

=head2 $format_nroff->b_end();

Process </B> tag. 

=cut

sub b_end {
    my $self = shift;

    if($self->{ignore}) { return 1; }

    $self->font_end();
}


=head2 $format_nroff->table_start($node);

Process <TABLE>, start table processing. $node
is the current html_parser node.

    Pass on the $format_nroff->{'page_width'} to FormatTableNroff

=cut

sub table_start {
    my($self, $node) = @_;

    if($self->{ignore}) { return 1; }

    if(defined($self->{'current_table'})) {
	push(@ {$self->{'tables'}},  $self->{'current_table'});
    }

    my %attr = (
		align => lc $node->attr('align'),
		width => lc $node->attr('width'),
		page_width => $self->{'page_width'},
		);

    unless($node->attr('align')) {
	if($self->{'center'}) {
	    $attr{align} = 'center';
	}
    }

    $self->{'current_table'} =  new HTML::FormatTableNroff($self, %attr);
}

=head2 $format_nroff->tr_start($node);

Process <TR>, add table row.

=cut

sub tr_start {
    my($self, $node) = @_;

    if($self->{ignore}) { return 1; }

    my %attr = (
		align => lc $node->attr('align'),
		valign => lc $node->attr('valign'),
		);

    $self->{'current_table'}->add_row(%attr);
}


=head2 $format_nroff->tr_end();

End the table row </TR>

=cut


sub tr_end {
    my($self) = @_;

}


=head2 $format_nroff->a_start();

<A> is ignored.

=cut

sub a_start {
    my($self) = @_;

}

=head2 $format_nroff->a_end();

</A> is ignored.

=cut

sub a_end {
    my($self) = @_;

}

=head2 $format_nroff->td_start($node);

Process <TD>, add table cell

=cut

sub td_start {
    my($self, $node) = @_;

    if($self->{ignore}) { return 1; }

    $self->start_data($node);
}

=head2 $format_nroff->td_end();

Process </TD>, end table cell

=cut

sub td_end {
    my $self = shift;

    if($self->{ignore}) { return 1; }

    $self->{'current_table'}->end_data();
}

=head2 $format_nroff->th_start($node);

Process <TH>, add table header cell

=cut

sub th_start {
    my($self, $node) = @_;

    if($self->{ignore}) { return 1; }

    $self->start_data($node, 'header');
}

# internal helping routine for processing table cells

sub start_data {
    my($self, $node, $header) = @_;
    
    if($self->{ignore}) { return 1; }

    my %attr = (
		header => $header,
		align => lc $node->attr('align'),
		valign => lc $node->attr('valign'),
		nowrap => lc $node->attr('nowrap'),
		rowspan => lc $node->attr('rowspan'),
		colspan => lc $node->attr('colspan'),
		);
    $self->{'current_table'}->start_data(%attr);
}
    
=head2 $format_nroff->th_end();

Process </TH>, end table header cell

=cut

sub th_end {
    my $self = shift;

    if($self->{ignore}) { return 1; }

    $self->{'current_table'}->end_data();
}

=head2 $format_nroff->table_end();

Process </TABLE>. Actually output entire table.

=cut

sub table_end {
    my $self = shift;

    if($self->{ignore}) { return 1; }

    $self->{'current_table'}->output();
    $self->{'current_table'} = pop(@{ $self->{'tables'} });
}


=head2 $format_nroff->p_start();

Process <P>.

=cut

sub p_start {
    my $self = shift;

    if($self->{ignore}) { return 1; }

    $self->textout("\n.PP\n");

}

=head2 $format_nroff->p_end();

Process </P> by doing nothing.

=cut

sub p_end {
    my $self = shift;

}

=head2 $format_nroff->goto_lm()

goto_lm does nothing.

=cut

sub goto_lm {
}

=head2 $format_nroff->br_start();

Process <BR>.

=cut

sub br_start {
    my $self = shift;

    if($self->{ignore}) { return 1; }

    $self->textout("\n.br\n");
}

=head2 $format_nroff->hr_start();

Process <HR>

=cut

sub hr_start {
    my $self = shift;

    if($self->{ignore}) { return 1; }

    $self->textout("\n.br\n.ta 6.5i\n.tc _\n\t\n.br\n");
}

=head2 $format_nroff->header_start();

Process <H?> simply using .SH

=cut

sub header_start {
    my($self, $level, $node) = @_;

    if($self->{ignore}) { return 1; }

    $self->textout("\n.SH ");    
    1;
}

=head2 $format_nroff->header_end();

Process </H?> simply outputing newline

=cut

sub header_end {
    my($self, $level, $node) = @_;

    if($self->{ignore}) { return 1; }

    $self->textout("\n");    
    1;
}

=head2 $format_nroff->out($text);

Output text.

=cut

sub out {
    my $self = shift;
    my $text = shift;

    if($self->{ignore}) { return 1; }

    if(defined $self->{vspace}) {
	$self->nl($self->{vspace});
	$self->{vspace} = undef;
    }

    if($text) { 
	$self->collect($text); 
    }
}

=head2 $format_nroff->pre_out($pre);

Output <PRE> text.

=cut

sub pre_out {
    my($self, $pre) = @_;

    if($self->{ignore}) { return 1; }

    if( defined $self->{vspace}) {
	$self->nl($self->{vspace});
	$self->{vspace} = undef;
    }
    my $indent = ' ' x $self->{lm};
    $pre =~ s/^/$indent/mg;
    $self->collect($pre);
    $self->{'out'}++;
}

=head2 $format_nroff->nl($cnt);

Output newline.

=cut

sub nl {
    my($self, $cnt) = @_;

    if($self->{ignore}) { return 1; }

    $self->collect("\n.sp $cnt\n");
    $self->{'out'}++;
}

=head2 $format_nroff->adjust_lm($indent);

adjust indent (left margin)

=cut

sub adjust_lm {
    my($self, $indent) = @_;

    $self->{lm} += $indent;
}

=head2 $format_nroff->adjust_rm();

not used.

=cut

sub adjust_rm {
    my $self = shift;
}


=head2 $format_nroff->bullet($tag);

output the bullet, using a temporary indent and the $tag

=cut

sub bullet {
    my($self, $tag) = @_;

    if($self->{'lm'} > 0) {
	$self->textout("\n.ti +" . $self->{'lm'} . "\n$tag "); 
    }
}

=head2 $format_nroff->textflow($node);

Output text or add it to table if currently inside a table
If centered add .ce unless inside a table, if underlined add .ul,
if the left margin is adjusted use a .ti for every new line.

=cut

sub textflow {
    my($self, $node) = @_;

    if($self->{ignore}) { return 1; }

    if( (!defined($self->{'current_table'})) and
       $self->{'center'}) {
	$self->textout("\n.ce\n"); 
    }
    if($self->{'underline'} ) {
	$self->textout("\n.ul\n"); 	
    }

    if($self->{'lm'} > 0) {
	my $repl = "\n.ti +" . $self->{'lm'} . "\n "; 
	$node =~ s/\n/$repl/;
    }

    if(defined($self->{'current_table'})) {

	$self->{'current_table'}->add_text($node) or
	    $self->SUPER::textflow($node);	    
    } else {
	$self->SUPER::textflow($node);	    
    }
}

sub textout {
    my($self, $text) = @_;

    if($self->{ignore}) { return 1; }

    if(defined($self->{'current_table'})) {
	$self->{'current_table'}->add_text($text) || 
	    $self->out($text);
    } else {
	$self->out($text);
    }
}

=head2 $format_nroff->blockquote_start($node);

Start <BLOCKQUOTE>, by making a new paragraph, and indenting.

=cut

sub blockquote_start {
    my($self, $node) = @_;

    $self->textout("\n.PP\n.in +5\n"); 
}

=head2 $format_nroff->blockquote_end($node);

</BLOCKQUOTE>, by ending indent, and making a new paragraph

=cut

sub blockquote_end{
    my($self, $node) = @_;

    $self->textout("\n.in -5\n.PP\n"); 
}

=head2 $format_nroff->div_start($node);

Process DIV

 <DIV TYPE="NROFF_IGNORE">
    is used to ignore all subsequent content until the next
 </DIV>

 This allows HTML to be used which is not to be converted to HTML
(such as navigation controls). Case is ignored in the type.

In the header you probably should use
 <META NAME="nroff-control" CONTENT="ignore_start">
    is used to ignore all subsequent content until the next
 <META NAME="nroff-control" CONTENT="ignore_end">

=cut

# all the push/pop is so we can safely ignore nested divs.

sub div_start {
    my($self, $node) = @_;

    my $type = lc $node->attr('type');
    
    push(@ {$self->{'divs'}}, $type);

    if($type =~ /nroff_ignore/) {
	$self->{'ignore'} = 1;
    }
}

sub div_end {
    my($self, $node) = @_;
    
    my $type = pop( @{ $self->{'divs'} });

    if($type =~ /nroff_ignore/) {
	$self->{ignore} = 0;
    }
}
=head2 $format_nroff->meta_start($node);

Process <META> tag. 

 <META NAME="nroff-control" CONTENT="ignore_start">
    is used to ignore all subsequent content until the next
 <META NAME="nroff-control" CONTENT="ignore_end">

 This allows HTML to be used which is not to be converted to HTML
(such as navigation controls). Case is ignored.

Strictly speaking META is only allowed in the HTML HEAD, so this
META. In the body, you should use:

    <DIV TYPE="NROFF_IGNORE">
    </DIV>

=cut

sub meta_start {
    my($self, $node) = @_;

    my $meta_name = lc $node->attr('NAME');
    unless ($meta_name eq 'nroff-control') {
        return 1;
    }
    my $meta_content = lc $node->attr('CONTENT');

    if($meta_content eq 'ignore_start') {
        $self->{'ignore'} = 1;
    } else {
        $self->{'ignore'} = 0;
    }
}

=head1 SEE ALSO

L<HTML::Formatter>,
L<HTML::FormatTableCell>,
L<HTML::FormatTableCellNroff>,
L<HTML::FormatTableNroff>,
L<HTML::FormatTableRow>,
L<HTML::FormatTableRowNroff>

=head1 COPYRIGHT

Copyright (c) 1997 Frederick Hirsch. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Frederick Hirsch <f.hirsch@opengroup.org>

=cut 

1;

