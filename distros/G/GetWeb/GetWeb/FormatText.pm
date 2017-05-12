require HTML::FormatText;
use URI::URL;

require 'dumpvar.pl';

package GetWeb::FormatText;
@ISA = qw( HTML::FormatText );

use strict;

my $DEFAULT_COLS = 20;
my $DEFAULT_SIZE = $DEFAULT_COLS;

# sub new
# {
#     my $type = shift;
#     my $self = $type -> SUPER::new(@_);
#     $$self{option_seen} = {};
#     $self;
# }

sub table_start
{
    shift -> vspace(1);
    1;
}

# jfj solve radio-link problem of extra <P> after <INPUT>

sub table_end
{
    shift -> vspace(1);
    1;
}

sub out
{
    my $self = shift;
    my $text = shift;

    if ($self -> {input})
    {
	$text = "[$text]";
    }

    if ($text =~ /^\s+$/)
    {
	$self -> {pending_space} = 1;
	return;
    }

    if ($self->{curpos} + length($text) > $self->{rm})
    {
	# line is too long, break it
	if ($self -> {curpos} > $self -> {lm} + 5)
	{
	    $text =~ s/^\s+//;
	    $self -> vspace(0);
	}
    }

    $self -> SUPER::out($text);
}

sub begin
{
    my $self = shift;
    my $retVal = $self->HTML::FormatText::begin (@_);

#    $self->{lm}  =    3;
    $self->{lm}  =    0;  # left margin
#    $self->{rm}  =   70;
    $self->{rm}  =   68;  # right margin


    $retVal;
}

sub form_start
{
    my ($self, $elem) = @_;

    $$elem{option_seen} = {};
    $$self{current_form} = $elem;
    
    my $phphpaInput = { 'radio' => {},
			'checkbox' => {} };

    $elem ->
	traverse(sub
		 {
		     my ($node, $start, $depth) = @_;	     
		     return 1 unless $start eq 1;
		     
		     my $tag = $node -> tag;
		     return 1 unless $tag eq 'input';
		     
		     my $type = $node -> attr('type');

		     my $phpaInput = $$phphpaInput{$type};
		     return 1 unless defined $phpaInput;

		     my $name = $node -> attr('name');
		     my $input_list = $$phpaInput{$name};
		     if (! defined $input_list)
		     {
			 $$phpaInput{$name} = [];
			 $input_list = $$phpaInput{$name};
		     }

		     push(@$input_list,$node);
		     1;
		 },
		 1);

    #$::gDump = $phphpaInput;
    #&::dumpvar('');

    my $phpaInput = $$phphpaInput{'radio'};
    my $paInput;
    foreach $paInput (values %$phpaInput)
    {
	my $oneChecked = 0;
	my $input;
	foreach $input (@$paInput)
	{
	    my $checked = $input -> attr('checked');
	    if ($checked)
	    {
		if ($oneChecked++)
		{
		    $input -> attr('checked',0);
		}
	    }
	}
	unless ($oneChecked)
	{
	    # check the first radio button
	    $paInput -> [0] -> attr('checked',1);
	}
    }

    # in case another programmer wants to use this structure
    $elem -> {phphpaInput} = $phphpaInput;

    1;
}

sub form_end
{
    delete shift -> {current_form};
}

sub input_start
{
    my $self = shift;
    my ($elem) = @_;

    if (! defined $elem -> attr('type'))
    {
	$elem -> attr('type','text');
    }
    $self -> input_route("start",@_);
}

sub input_end
{
    shift -> input_route("end",@_);
}

sub input_route
{
    my $self = shift;
    my $direction = shift;
    my ($elem) = @_;

    my $type = $elem -> attr('type');
    $type = lc $type;
    # defined $type or $type = 'text';

    my $func = "input_${type}_$direction";
    my $retval = eval { $self -> $func(@_) };
    $@ ? 1 : $retval;
}

sub input_text_out
{
    my ($self,$size,$text) = @_;

    $text =~ s^[\[\]\\_]^\\$&^g;

    my $out;

    if (length($text) + 2 > $size)
    {
	$out = "_${text}_";
    }
    else
    {
	$out = '_' x $size;
	substr($out,1,length($text)) = $text;
    }
    #$out =~ /_$/ or $out .= '_';
    $self -> {input}++;
    $self -> out("$out");
    $self -> {input}--;
}

sub input_text_start
{
    my ($self, $elem) = @_;

    my $size = $elem -> attr('size') || $DEFAULT_SIZE;
    my $value = $elem -> attr('value');

    $self -> input_text_out($size,$value);
    1;
}

sub textarea_start
{
    my ($self, $elem) = @_;

    my $rows = $elem -> attr('rows');
    my $cols = $elem -> attr('cols') || $DEFAULT_COLS;

    my $content_line;
    my $content = $elem -> content;
    while ($content_line = shift @$content
	   or $rows > 0)
    {
	next if ref($content_line);
	$self -> vspace(0);
	$rows--;
	$self -> input_text_out($cols,$content_line);
    }

    if ($rows < 0)
    {
	# expand row count
	my $newRows = $elem -> attr('rows') - $rows;
	$elem -> attr('rows',$newRows);
    }

    0;
}

sub input_password_start
{
    shift -> input_text_start(@_);
}

sub checkbox_out
{
    my ($self, $filled) = @_;

    my $text = $filled?"X":" ";
    $self -> {input}++;
    $self -> out("$text");
    $self -> {input}--;
}

sub input_checkbox_start
{
    my ($self, $elem) = @_;

    my $checked = $elem -> attr('checked');
    $self -> checkbox_out($checked);

    1;
}

sub input_radio_start
{
    my $self = shift;
    my ($elem) = @_;
#    my $name = $elem -> attr('name');

#     my $radio_seen = $$self{radio_seen};
#     if ($$radio_seen{$name}++)
#     {
# 	$self -> out(" OR ");
#     }

    $self -> out("(");
    $self -> input_checkbox_start(@_);
    $self -> out(")");
}

sub vspace
{
    my $self = shift;
    #my ($package, $filename, $line) = caller;
    #$self -> collect("v $package $filename $line \n");
    #my ($package, $filename, $line) = caller(1);
    #$self -> collect("v $package $filename $line \n");
    #my ($package, $filename, $line) = caller(2);
    #$self -> collect("vspacing from $package $filename $line \n");
    $self -> SUPER::vspace(@_);
}

sub input_image_start
{
    my $self = shift;

    $self -> out(" [IMAGE] -");
    $self -> input_submit_start(@_);
}

sub button_out
{
    my ($self,$default,$text) = @_;
    $text = $default unless defined $text;

    $self -> out(" ");
    $self -> {input}++;
    $self -> out("$text");
    $self -> {input}--;
    $self -> out(" ");
}

sub input_submit_start
{
    my ($self, $elem) = @_;
    my $text = $elem -> attr('value');
    $self -> button_out("submit",$text);
    1;
}

sub input_reset_start
{
    my ($self, $elem) = @_;
    my $text = $elem -> attr('value');
    $self -> button_out("reset",$text);
    1;
}

# jfjf handle file upload

sub option_start
{
    my $self = shift;
    my ($elem) = @_;

    defined $self -> {current_form} or
	die "no form defined";

    my $name = $self -> {select_name};
    my $option_seen = $self -> {current_form} -> {option_seen};

    $self -> vspace(0);

    my $conjunction = $$self{conj};

    my $need_conj = $$option_seen{$name}++;

    if ($need_conj)
    {
	$self -> out($conjunction);
    }
    else
    {
	$self -> adjust_lm(length($conjunction));
    }

    $self -> option_out(@_);
    $self -> {pending_space} = 1;

    $self -> adjust_lm(-length($conjunction))
	unless $need_conj;

    1;
}

sub option_out
{
    my ($self, $elem) = @_;

    my $multiple = $elem -> attr('multiple');
#    my $type = $multiple?'checkbox':'radio';
#    my $name = $self -> {select_name};
    my $selected = $elem -> attr('selected');

#     my $value = $elem -> attr('value');
#     if (! defined $value)
#     {
# 	my $content = $elem -> content;
# 	$value = join('',@$content);
#     }

    $self -> checkbox_out($selected);

#     my $input = new HTML::Element ('input',
# 				   'type' => $type,
# 				   'name' => $name,
# 				   'value' => $value);

#     $input -> attr('checked',1)
# 	if $selected;

#     $self -> input_start($input);
#     $self -> input_end($input);
}

sub select_start
{
    my ($self, $elem) = @_;

    $self -> vspace(1);
    $self->adjust_lm( +2 );
    $self->adjust_rm( -2 );

    $$self{select_name} = $elem -> attr('name');
    $$self{current_select} = $elem;

    my $multiple = $elem -> attr('multiple');
    $$self{conj} = $multiple?'AND/OR ':'OR ';
    return 1 if $multiple;

    my $select = $elem;

    # select first radio button if no others selected
    $elem ->
	traverse(sub
		 {
		     my ($node, $start, $depth) = @_;
		     return 1 unless $start eq 1;

		     my $tag = $node -> tag;
		     return 1 unless $tag eq 'option';
  
		     defined $$select{first_option} or
			 $$select{first_option} = \$node;

		     if (defined $node -> attr('selected'))
		     {
			 # avoid duplicates, protect from bad HTML
			 if ($$select{one_selected})
			 {
			     #print "deselecting\n";
			     $node -> attr('selected',0);
			 }
			 else
			 {
			     #print "noting\n";
			     $$select{one_selected} = 1;
			 }
		     }
		     1;
		 },
		 1);
    if (! defined $$elem{one_selected})
    {
	${$elem -> {first_option}} -> attr('selected',1);
    }

    1;
}

sub select_end
{
    my ($self, $elem) = @_;
    $self -> vspace(1);
    $self->adjust_lm( -2 );
    $self->adjust_rm( +2 );
}    

sub tr_start
{
    shift -> vspace(0);
    1;
}

sub tr_end
{
    shift -> vspace(0);
    1;
}

sub li_start
{
    my $self = shift;

    # jf reduce spacing of recursive lists

    # make list spacing more regular
    $self->{pending_space} = 0;

    $self-> HTML::FormatText::li_start (@_);
}

sub li_end
{
    my $self = shift;

    #self -> vspace(1);
    # vspace is 1 in FormatText, single-spaced lists are more standard, so:
    $self->vspace(0);
                        
    $self->adjust_lm(-2);
    my $markers = $self->{markers};
    if ($markers->[-1] =~ /^\d+/) {
	# increment ordered markers
	$markers->[-1]++;
    }
}

sub font_start
{
    my($self, $elem) = @_;
    my $size = $elem->attr('size');
    return 1 unless defined $size;
    if ($size =~ /^\s*[+\-]/) {
	my $base = $self->{basefont_size}[-1];
	$size = $base + $size;
    }
    push(@{$self->{font_size}}, $size);
    1;
}

sub basefont_start
{
    my($self, $elem) = @_;
    my $size = $elem->attr('size');
    return 1 unless defined $size;
    push(@{$self->{basefont_size}}, $size);
    1;
}

1;
