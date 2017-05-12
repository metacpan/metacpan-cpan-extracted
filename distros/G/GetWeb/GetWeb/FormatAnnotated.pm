require GetWeb::FormatText;
use URI::URL;
use GetWeb::Util;

package GetWeb::FormatAnnotated;
@ISA = qw( GetWeb::FormatText );

use Carp;
use strict;

# jfj center <Hn> tags, remove ======= underlining
# jfj always have exactly one space under <Hn> tags
# jfj indent <address> blocks

sub new
{
    my $type = shift;
    my $baseURL = shift;

    my $self = new GetWeb::FormatText (@_);
    $$self{baseURL} = $baseURL;

    my $paLink = [];
    if (defined $baseURL)
    {
	push(@$paLink, "[orig] $baseURL");
    }
    else
    {
	push(@$paLink,"[orig]");
    }
    $$self{paLink} = $paLink;

    $$self{paForm} = [];
    $$self{formCount} = 'A';
    bless($self,$type);
    $self;
}

sub form_start
{
    my $self = shift;
    my ($elem) = @_;

    my $paForm = $self -> {paForm};
    push(@$paForm,$elem);

    my $letter = $self -> {formCount}++;
    $elem -> {letter} = $letter;

    $self -> vspace(1);
    $self -> out("<GETWEB: FORM $letter>");
    $self -> vspace(1);

    $elem -> {elementCount} = 'a';
    $elem -> {elementList} = [];

    my $ret = $self -> SUPER::form_start(@_);

    my $phphpaInput = $elem -> {phphpaInput};
    my $phpaInput;
    foreach $phpaInput (values %$phphpaInput)
    {
	my $paInput;
	foreach $paInput (values %$phpaInput)
	{
	    $paInput -> [-1] -> {lastInput} = 1;
	}
    }
    $ret;
}

sub out
{
    my $self = shift;
    my $text = shift;

    if (defined $self -> {current_form})
    {
	# print "text is $text\n";
	$text =~ s/[\\\[\]]/\\$&/g;
	if ($self -> {input})
	{
	    $text =~ s/\d/\\$&/g
		unless $self -> {href};
	}
    }
    $self -> SUPER::out($text, @_);
}

sub record_form_element
{
    my ($self, $elem) = @_;

    my $form = $self -> {current_form};
    my $elementList = $form -> {elementList};
    my $elementCount = $form -> {elementCount}++;

    push(@$elementList,$elem);

    $elem -> {letter} = $elementCount;
}

sub note_form_element
{
    my $self = shift;
    my ($elem) = @_;

    $self -> record_form_element(@_);
    my $letter = $elem -> {letter};

    # $self -> out(" {$letter} ");
}

sub input_hidden_start
{
    my $self = shift;
    my ($elem) = @_;

    $self -> record_form_element(@_);
    $self -> SUPER::input_hidden_start(@_);
}

sub input_password_start
{
    my $self = shift;
    my ($elem) = @_;

    $self -> out(" <WARNING: INSECURE> ");
    $self -> SUPER::input_password_start(@_);
}

sub input_text_start
{
    my $self = shift;

    my $ret = eval {$self -> SUPER::input_text_start(@_)};
    $ret = $@?1:$ret;
    $self -> note_form_element(@_);
    $ret;
}

sub input_submit_start
{
    my $self = shift;

    my $ret = eval {$self -> SUPER::input_submit_start(@_)};
    $ret = $@?1:$ret;
    $self -> note_form_element(@_);
    $ret;
}

sub button_out
{
    my ($self,$default,$text) = @_;
    $text = $default unless defined $text;

    # my $letter = $self -> {current_form} -> {letter};

    $self -> vspace(0);

    $self -> {input}++;
    $self -> out(" ");
    $self -> {input}--;
    $self -> out(" $text: check preceding box, forward entire document to GetWeb");

    $self -> vspace(0);
}

sub input_reset_start
{
    0;
}

sub note_if_final
{
    my ($self, $type, $elem) = @_;

    my $form = $self -> {current_form};
    
    my $letter = $elem -> {letter};
    if (! defined $letter)
    {
	$letter = $form -> {elementCount}++;
	my $form = $self -> {current_form};
	defined $form or die "no current form";
	my $phpaInput = $form -> {phphpaInput} -> {$type};

	my $name = $elem -> attr('name');
	my $paInput = $phpaInput -> {$name};

	my $input;
	foreach $input (@$paInput)
	{
	    $input -> {letter} = $letter;
	}

	my $elementList = $form -> {elementList};
	push(@$elementList,$elem);
    }
    
    my $text = "";
    my $currentBoxLetter = $form -> {currentBoxLetter};
    if (defined $currentBoxLetter and $currentBoxLetter ne $letter)
    {
	$text = "-$currentBoxLetter,";
    }
    $text .= $letter if $elem -> {lastInput};
    # $self -> out(" {$text} ") if $text ne "";
}

sub input_radio_start
{
    my $self = shift;

    my $ret = eval {$self -> SUPER::input_radio_start(@_)};
    $ret = $@?1:$ret;
    $self -> note_if_final('radio',@_);
    $ret;
}

sub input_checkbox_start
{
    my $self = shift;

    my $ret = eval{$self -> SUPER::input_checkbox_start(@_)};
    $ret = $@?1:$ret;
    $self -> note_if_final('checkbox',@_);
    $ret;
}

sub select_end
{
    my $self = shift;
    
    $self -> note_form_element(@_);
    my $ret = eval{$self -> SUPER::select_end(@_)};
    $ret = $@?1:$ret;
    $ret;
}

sub textarea_end
{
    my $self = shift;

    $self -> note_form_element(@_);
    my $ret = eval{$self -> SUPER::textarea_end(@_)};
    $ret = $@?1:$ret;
    $ret;
}


sub a_end
{
    my $self = shift;

    my $paLink = $$self{paLink};
    my $count = @$paLink;  #number of links; [orig] is link 0

    my $href = $_[0] -> {'href'};
    my $url = new URI::URL $href, $$self{baseURL};

    # jfj handle specially links pointing back to the same document,
    # jfj handle anchors

    my $footnote = "[$count] " . $url -> abs;

    my $scheme = $url -> scheme;
    
    if ((defined $scheme) and
	(($scheme eq 'telnet') or ($scheme eq 'news')))
    {
	$footnote .= " (not implemented)";
    }

    push(@{$paLink}, $footnote);

    $self -> {href}++;
    $self -> {input}++;
    $self -> out($count);
    $self -> {input}--;
    $self -> {href}--;

    $self -> HTML::FormatText::a_end (@_);
}

# client-side image maps

sub map_start
{
    my $self = shift;
    $self -> vspace(1);
    $self -> out("[IMAGE MAP]");
    1;
    #shift -> a_start(@_);
    #1;
}

sub map_end
{
    my $self = shift;
    $self -> vspace(1);
}

sub area_start
{
    my $self = shift;

    # jfj abstract linking to another module
    $self -> a_end(@_);
}

sub option_start
{
    my $self = shift;
    my ($elem) = @_;

    my $value = $elem -> attr('value');
    if (! defined $value)
    {
 	my $content = $elem -> content;
 	$value = join('',@$content);
	$value =~ s/\n/ /g;
	$value =~ s/\s+$//;
	$value =~ s/^\s+//;
	$elem -> attr('value',$value);
    }
    $self -> SUPER::option_start(@_);
}

sub conciseStart
{
    my ($self, $element) = @_;

    my $tag = $element -> tag;
    my $abbrev = new HTML::Element $tag;
    my @preserveUs = qw( name type action method rows multiple );
    my $type = lc $element -> attr('type');
    push(@preserveUs,'value') if (grep ($_ eq $type,
				       (qw( submit radio checkbox
					   image hidden )))
				  or $tag eq 'option');

    # push(@preserveUs,'letter') if $tag eq 'form';
    
    my $preserveMe;
    foreach $preserveMe (@preserveUs)
    {
	my $value = $element -> attr($preserveMe);
	defined $value and
	    $abbrev -> attr($preserveMe,$value);
    }
    my $ret = $abbrev -> starttag;
    $ret;
}

sub annotateForm
{
    my ($self,$form) = @_;

    my $phphpaInput = $form -> {phphpaInput};
    my $formLetter = $form -> {letter};
    my $paElement = $form -> {elementList};

    $self -> out($self -> conciseStart($form));
    $form -> traverse(sub
		      {
			  my ($node, $start, $depth) = @_;
			  
			  my $tag = $node -> tag;
			  return 1 unless grep($_ eq $tag,
					       (qw( input option
						   select textarea )));

			  my $out;
			  if ($start eq 1)
			  {
			      $out = $self -> conciseStart($node);
			      if ($tag ne 'option')
			      {
				  $self -> vspace(0);
			      }
			  }
			  else
			  {
			      return 1 unless grep($_ eq $tag,
						   (qw( select textarea )));
			      
			      $out = $node -> endtag;
			  }
			  $self -> out($out);
			  1;
		      },
		      1);
    $self -> out($form -> endtag);


    #$self -> out("$formLetter=" . $self -> conciseHTML($form) . ";");
    
#     my $element;
#     foreach $element (@$paElement)
#     {
# 	my $elementLetter = $element -> {letter};
# 	my $id = "$formLetter.$elementLetter";

# 	my $abbrev = $self -> conciseHTML($element);

# 	my $out = "$id=" . $abbrev . ";";
# 	$self -> out($out);
# 	$self -> vspace(0);
	
# 	my $count = 0;

# 	my $tag = $element -> tag;
# 	if ($tag eq 'select')
# 	{
# 	    $element -> traverse(sub {
# 		my ($node, $start, $depth) = @_;
# 		return 1 unless $start eq 1;
		
# 		my $tag = $node -> tag;
# 		return 1 unless $tag eq 'option';
		
# 		$count++;
# 		my $value = $node -> attr('value');
# 		if (! defined $value)
# 		{
# 		    my $content = $node -> content;
# 		    $value = join('',@$content);
# 		}
# 		$self -> out("$id.$count=$value;");
# 		$self -> vspace(0);
# 		1;
# 	    },
# 				 1);
# 	}
	
# 	my $phpaInput;
	
#       LOOP:
# 	foreach $phpaInput (values %$phphpaInput)
# 	{
# 	    my $paInput;
# 	    foreach $paInput (values %$phpaInput)
# 	    {
# 		$paInput -> [0] -> {letter} eq $elementLetter
# 		    or next LOOP;			    
		
# 		my $input;
# 		foreach $input (@$paInput)
# 		{
# 		    $count++;
# 		    my $value = $input -> attr('value');
# 		    $self -> out("$id.$count=$value;");
# 		    $self -> vspace(0);
# 		}
# 	    }
# 	}
#    }
}

sub end
{
    my $self = shift;

    my $paForm = $self -> {paForm};

    if (@$paForm)
    {
	$self -> vspace(1);
	$self -> out(&GetWeb::Util::getFormRefTag);
	$self -> vspace(0);

	my $form;
	foreach $form (@$paForm)
	{
	    $self -> annotateForm($form);
	}
    }

    my $paLink = $$self{paLink};
    if (@$paLink > 1 or defined $self -> {baseURL})  # skip if no links
    {
	$self -> vspace(1);
	$self -> out("\n" . &GetWeb::Util::getRefTag);
	
	my $count = 0;
	while (@{$paLink})
	{
	    $self -> vspace(0);
	    my $line = shift @$paLink;
	    my $maxLength = $self -> {rm} - $self -> {lm} + 1;
	    if (length($line) > $maxLength)
	    {
		$maxLength -= 5;
		$line =~ s/.{$maxLength}(?=.{5})/$&\\\n/g;
	    }
	    $self -> out($line);
	}
    }

    $self->HTML::FormatText::end (@_);
}

1;
