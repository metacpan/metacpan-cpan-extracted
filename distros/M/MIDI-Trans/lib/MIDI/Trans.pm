package MIDI::Trans;

use 5.006;
use strict;
use warnings;

use MIDI::Simple;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MIDI::Trans ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.15';


# Preloaded methods go here.

sub new {

 my $class = shift;
 my $self=bless {}, ref($class)||$class;

 $self->_init(@_);

 return $self;

}

sub _init {

 my $self = shift;
 my $opt_HR = shift;

     # default values

 $self->{'Raise_Error'} = 0;
 $self->{'ERRx1'} = undef;
 $self->{'ElementDelimiter'} = '\s+';
 $self->{'SentenceDelimiter'} = '\.|\!|\?|';
 $self->{'NoteCallBack'} = undef;
 $self->{'VolumeCallBack'} = undef;
 $self->{'DurationCallBack'} = undef;
 $self->{'TempoCallBack'} = undef;
 $self->{'AllAttributes'} = 1;
 $self->{'OpenFiles'} = ();
 $self->{'CurElem'} = undef;
 $self->{'CurPos'} = undef;
 $self->{'Channel'} = 1;
 $self->{'Events'} = ();
 $self->{'qn_len'} = 96;
 $self->{'BaseMilliseconds'} = 60000000;
 $self->{'Tempo'} = 120;
 $self->{'CCorp'} = undef;
 $self->{'TransObj'} = undef;
 
 foreach my $key ('Raise_Error','ElementDelimiter','NoteCallBack','VolumeCallBack','DurationCallBack','SentenceDelimiter','AllAttributes','Channel','qn_len', 'TempoCallBack', 'Tempo') {
     map {$self->{$_}=$opt_HR->{$_}} ($key) if(defined($opt_HR->{"$key"}));
     }
     
 return(1);
}


sub error {

 my $self = shift;
 return($self->{'ERRx1'}) if(!defined($_[0]));

 if($self->raise_error()) {
     die("[MIDI::Trans] ERROR: $_[0]\n");
     } else {
         $self->{'ERRx1'} = $_[0];
         return($self->{'ERRx1'});
         }
}

sub raise_error {

 my $self = shift;
 
 $self->{'Raise_Error'} = $_[0] if(defined($_[0]));
 return($self->{'Raise_Error'});
}


sub delimiter {

 my $self = shift;
 
 $self->{'ElementDelimiter'} = $_[0] if(defined($_[0]));
 return($self->{'ElementDelimiter'});
}

sub sentence_delimiter {

 my $self = shift;

 $self->{'SentenceDelimiter'} = $_[0] if(defined($_[0]));
 return($self->{'SentenceDelimiter'});
}

sub all_attributes {

 my $self = shift;
 $self->{'AllAttributes'} = $_[0] if(defined($_[0]));
 return($self->{'AllAttributes'});
}

sub channel {

 my $self = shift;
 $self->{'Channel'} = $_[0] if(defined($_[0]));
 return($self->{'Channel'});
}

sub read_corpus {

 my $self = shift;
 my $hRef = shift;
 
 if(!defined($hRef) || ref($hRef) ne 'HASH') {
    $self->error("[read_corpus] ERROR: HASHREF Argument Required.");
    return(undef);
    }

 my($data,$file);
 my $lines = 0;
 my $delim = $self->delimiter();
 my $sent_delim = $self->sentence_delimiter();

 if(exists($hRef->{'File'}) && defined($hRef->{'File'})) {

    $file = $hRef->{'File'};
    
    if(open(TRFH,$file)) {
        
        while(<TRFH>) {
            chomp;
            $data .= $_;
            $lines++;
            }
            
        close(TRFH);
        
        return(1) if(length($data) < 1);
        
            # could not open file...
        } else {
            $self->error("[read_corpus] ERROR: Could not open $hRef->{'File'} -> $!");
            return(undef);
            }

    } elsif(exists($hRef->{'String'}) && defined($hRef->{'String'})) {
        $data = $hRef->{'String'};
        return(1) if(length($data) < 1);
        }
        

 my %hash = ();
 
 $hash{'Name'} = $hRef->{'Name'} || $file if(defined($file));
 $hash{'Name'} = $hRef->{'Name'} || 'String' if(!defined($file));

     # if we calculate all attributes...

 if ($self->all_attributes()) {
     my @Sentences = split(/(?:$sent_delim)/,$data);
     $hash{'NumSent'} = $#Sentences + 1;

     undef(@Sentences);

     my @words = split(/\b/,$data);
     $hash{'NumWords'} = $#words + 1;

     undef(@words);
     } else {
        # otherwise... set to undef
        $hash{'NumSent'} = 0;
        $hash{'NumWords'} = 0;
        }

            # get our elements on the delimiter

 my @elems = split(/(?:$delim)/,$data);
 $hash{'NumElems'} = $#elems + 1;
 $hash{'Elems'} = \@elems;

 push(@{ $self->{'OpenFiles'} },\%hash);
 
 return(1);
}


sub sentences {

 my $self = shift;
 
 my $cur_corp = $self->_cur_corpus();
 
 return($self->{'OpenFiles'}[$cur_corp]->{'NumSent'});
}

sub words {

 my $self = shift;
 
 my $cur_corp = $self->_cur_corpus();
 
 return($self->{'OpenFiles'}[$cur_corp]->{'NumWords'});
}

sub elements {

 my $self = shift;
 
 my $cur_corp = $self->_cur_corpus();
 
 return($self->{'OpenFiles'}[$cur_corp]->{'NumElems'});
}

sub _cur_corpus {

 my $self = shift;
 
 $self->{'CCorp'} = $_[0] if(defined($_[0]));
 return($self->{'CCorp'});
}


sub current_elem {

 my $self = shift;

 $self->{'CurElem'} = $_[0] if(defined($_[0]));
 return($self->{'CurElem'});
}

sub current_pos {

 my $self = shift;

 $self->{'CurPos'} = $_[0] if(defined($_[0]));
 return($self->{'CurPos'});
}


sub note_callback {
 my $self = shift;

 $self->{'NoteCallBack'} = $_[0] if(defined($_[0]));
 return($self->{'NoteCallBack'});
}


sub tempo_callback {
 my $self = shift;

 $self->{'TempoCallBack'} = $_[0] if(defined($_[0]));
 return($self->{'TempoCallBack'});
}


sub duration_callback {
 my $self = shift;

 $self->{'DurationCallBack'} = $_[0] if(defined($_[0]));
 return($self->{'DurationCallBack'});
}


sub volume_callback {
 my $self = shift;

 $self->{'VolumeCallBack'} = $_[0] if(defined($_[0]));
 return($self->{'VolumeCallBack'});
}


sub qn_len {

 my $self = shift;
 
 $self->{'qn_len'} = $_[0] if(defined($_[0]));
 return($self->{'qn_len'});
}

sub trans_obj {

 my $self = shift;
 
 $self->{'TransObj'} = $_[0] if(defined($_[0]));
 return($self->{'TransObj'});
}
 

sub round {

 my $self = shift;
 my $val = shift;
 
 $val = $val < int($val) + .5 ? int($val) : int($val) + 1;
 
 return($val);
}


sub _get_num_by_name {

 my $self = shift;
 my $name = shift;
 
 return(undef) if(!defined($name));
 
 my $aRef = \@{ $self->{'OpenFiles'} };
 
 foreach (0..$#{ $aRef }) {
    my $hRef = \%{ $aRef->[$_] };
    return($_) if($hRef->{'Name'} eq $name);
    }
    
 return(undef);
}


sub tempo {

 my $self = shift;
 
 $self->{'Tempo'} = $_[0] if(defined($_[0]));
 return($self->{'Tempo'});
}

sub base_milliseconds {

 my $self = shift;
 
 $self->{'BaseMilliseconds'} = $_[0] if(defined($_[0]));
 return($self->{'BaseMilliseconds'});
}


sub process {

 my $self = shift;
 my $hRef = shift;
 
 my $num = undef;


 if($#{ $self->{'OpenFiles'} } < 0) {
    $self->error("[process] No Files/Strings Have Been Read\n");
    return(undef);
    }
    
 if(exists($hRef->{'Name'}) && defined($hRef->{'Name'})) {
    my $name = $hRef->{'Name'};
    $num = $self->_get_num_by_name("$name");
    if(!defined($num)) {
        $self->error("[process] No Data Found With Name '$name'");
        return(undef);
        }
    } elsif(exists($hRef->{'Num'}) && defined($hRef->{'Num'})) {
        $num = $hRef->{'Num'};
        if(!defined($self->{'OpenFiles'}[$num])) {
            $self->error("[process] No Data Found In Entry #$num");
            return(undef);
            }
        } else {
            $num = 0;
            }

 my $aRef = \@{ $self->{'OpenFiles'}[$num]->{'Elems'} };

 $self->_cur_corpus($num);
 
 if(defined($self->tempo_callback)) {
     my $tempo_c = $self->tempo_callback();
     my $tempo = &$tempo_c();
    $self->tempo($tempo);
    }
    
 foreach my $elem (0..$#{ $aRef }) {
    $self->current_elem($aRef->[$elem]);
    $self->current_pos($elem);

    my $note_c = $self->note_callback();
    my $vol_c = $self->volume_callback();
    my $dur_c = $self->duration_callback();
    
    my $note = &$note_c($aRef->[$elem],$elem);
    my $vol = &$vol_c($aRef->[$elem],$elem);
    my $dur = &$dur_c($aRef->[$elem],$elem);
    
    $self->_store_events($num,$note,$vol,$dur);
    }
    
 return(1);
}

sub _store_events {

 my $self = shift;
 my $num = shift;
 my $note = shift;
 my $vol = shift;
 my $dur = shift;

 return(undef) if(!defined($num) || !defined($note) || !defined($vol) || !defined($dur));
 
 $self->{'Events'}{$num} = () if(!exists($self->{'Events'}{$num}));
 
 push(@{ $self->{'Events'}{$num} },[$note,$vol,$dur]);
 return(1);
}
 
sub create_score {

 my $self = shift;
 my $num = shift;
 
 $num = 0 if(!defined($num));

 if(!defined($self->{'Events'}{$num})) {
    $self->error("[create_score] No Events Have Been Generated For Entry #$num");
    return(undef);
    }

 my $aRef = \@{ $self->{'Events'}{$num} };
 
 my $scoreObj = MIDI::Simple->new_score({ 'Tempo' => $self->qn_len() });
 
 my $tempo_qn = $self->tempo();

 my $bm = $self->base_milliseconds();
 
 my $tempo_act = $self->round($self->base_milliseconds() / $tempo_qn);
 my $channel = $self->channel();

 $scoreObj->set_tempo($tempo_act);
 
 foreach my $elem (0..$#{ $aRef }) {
    my $eRef = \@{ $aRef->[$elem] };
    next if($#{ $eRef } < 0);
    if($eRef->[0] eq 'rest') {
        $scoreObj->r("c$channel","v$eRef->[1]","d$eRef->[2]");
        } else {
            $scoreObj->n("c$channel","v$eRef->[1]","d$eRef->[2]","n$eRef->[0]");
            }
    }
    
 return($scoreObj);
}

sub reset_error {

 my $self = shift;
 $self->{'ERRx1'} = undef;
 return(1);
}

sub write_file {

 my $self = shift;
 my $file = shift;
 my $scoreObj = shift;
 
 if(!defined($file) || !defined($scoreObj)) {
    $self->error("[write_file] Arguments FILE, OBJECT expected");
    return(undef);
    }
    
 eval { $scoreObj->write_score($file); };
 
 if($@) {
    $self->error("[write_file] MIDI::Simple Returned: $@");
    return(undef);
    }
    
 return(1);
}

sub trans {

 my $self = shift;
 my $hRef = shift;
 
 my $file_o = $hRef->{'Outfile'} || './out.midi';
 my $file = $hRef->{'File'};
 my $vol_c = $hRef->{'Volume'} || $self->volume_callback();
 my $note_c = $hRef->{'Note'} || $self->note_callback();
 my $dur_c = $hRef->{'Duration'} || $self->duration_callback();
 my $tempo_c = $hRef->{'TempoCallBack'} || $self->tempo_callback();
 my $delim = $hRef->{'Delimiter'} || $self->delimiter();
 my $tempo = $hRef->{'Tempo'} || $self->tempo();
 
 if(!defined($file)) {
    $self->error("[trans] FILE Argument not specified");
    return(undef);
    }
    
 if(!defined($dur_c) || !defined($note_c) || !defined($vol_c)) {
    $self->error("[trans] DURATION, NOTE, and VOLUME callbacks must be specified");
    return(undef);
    } elsif(!defined($tempo_c) && !defined($tempo)) {
        $self->error("[trans] Either TEMPO or TEMPOCALLBACK must be specified");
        return(undef);
        }

 my $new_object = MIDI::Trans->new( {
        'VolumeCallBack' => $vol_c,
        'DurationCallBack' => $dur_c,
        'NoteCallBack' => $note_c,
        'TempoCallBack' => $tempo_c,
        'Tempo' => $tempo,
        'Delimiter' => $delim });
        
 if(!defined($new_object)) {
    $self->error("[trans] Error Creating Object");
    return(undef);
    }

 $self->trans_obj($new_object);
 
 $self->tempo_callback($tempo_c) if(!defined($tempo));
 $self->tempo($tempo) if(defined($tempo));

 if($new_object->read_corpus({ 'File' => "$file" })) {
    if($new_object->process({ 'Name' => "$file" })) {
        my $scoreObj = $new_object->create_score(0);
        if(defined($scoreObj)) {
            if($new_object->write_file($file_o,$scoreObj)) {
                return(1);
                } else {
                    $self->error($new_object->error());
                    return(undef);
                    }
            } else {
                $self->error($new_object->error());
                return(undef);
                }
        } else {
            $self->error($new_object->error());
            return(undef);
            }
    } else {
        $self->error($new_object->error());
        return(undef);
        }
 
return(undef);
}


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

MIDI::Trans - Perl extension for quick and easy text->midi conversion.

=head1 SYNOPSIS

  use MIDI::Trans;
  
  my $TranObj = MIDI::Trans->new( {
        'Delimiter' => '\s+',
        'Note' => \&note,
        'Volume' => sub { return(127); },
        'Duration' => \&somesub,
        'Tempo' => sub { ... }
        } );

  if($TransObj->trans( { 'File' => 'text.txt', 'Outfile' => 'out.mid' })) {
    print("success\n");
    } else {
        my $error = $TransObj->error();
        die("ERR: $error\n");
        }
        

  sub note {
    # do something
    # return a value between 0 and 127
    # or string 'rest' (sans quotes) for
    # a rest event
    }
    
  sub duration {
    # return some number of quarter notes
    }


=head1 DESCRIPTION

MIDI::Trans serves as a quick development foundation for text to midi
conversion algorithms utilizing MIDI::Simple for output.  Using MIDI::Trans, you
create callbacks for generating note, volume, duration and tempo values.
As your corpus is read, these callbacks are utilized to generate your
midi score by MIDI::Trans.  MIDI::Trans is modelled after the text conversion
aspects of TransMid (http://www.digitalkoma.com/church/projects/transmid/),
but designed to be more useful to a wider range of tasks, with less overhead.

If you're in a big hurry, and haven't any need for great control
over the process, simply read the 'Plug and Play Usage' and 'CallBacks'
sections below to get a jump, and your converter implemented in a just a few
minutes, with just a few statements.

A corpus can be defined as either a string, or text file.  MIDI::Trans
will then split that corpus into elements based on an element delimiter,
provided via argument, and determine some attributes of the corpus based
on other data, which can be supplied by the developer.  The corpus is
then processed, element by element through the use of CallBacks you
specify.  The normal flow of development looks like this:

    Define Parameters For Conversion
    Define Functions To Generate Note, Duration, Volume, Tempo
        from parameters and element values.
    Specify and process corpus
    Create score
    Write Output


... this section not yet complete...

=head2 EXPORT

None by default.

=head1 PLUG AND PLAY USAGE

A MIDI::Trans converter can be written in as few as three statements:

    use MIDI::Trans;
    
    my $TransObj = MIDI::Trans->new( {
        'Tempo' => 140,
        'VolumeCallBack' => sub { return(127); },
        'NoteCallBack' => sub { $cnt++; return $cnt % 4 ? 88 : 'rest'; },
        'DurationCallBack' => sub { return(16); },
        });
        
    $TransObj->trans({ 'File' => './test.txt', 'Outfile' => 'test.mid' });

Obviously, this isn''t very functional and the more compact we
make our code, the less functionality there is available to us.

However, if your conversion process doesn''t rely too heavily on
controlling the the act of conversion its self, this single method
will do everything you need for the process of conversion.

Let's discuss what we've done here:

    The new() method is called, which initializes the parameters
    for the converter.  The object returned makes its self
    available to the callbacks, assuming that you''ve created the
    variable referencing the object in the same namespace as, or at
    least scoped as visible to, the callbacks'' function definition.
    
    The trans() method acts as a wrapper around the step by step
    process of converting the document.  It doesn''t give you the
    ability to control some of the information gathering aspects,
    nor does it let you handle more than one corpus with a single
    object, but what it lacks in functionality, it makes up for in
    ease.
    
=head2 THE TRANS METHOD

trans HASHREF

    Has one argument, which is required: either a reference to, or
    an anonymous hash.  This hash contains information required to
    perform the conversion.  If any values have already been defined
    via the new() method, they do not have to be re-defined here.
    Some names are short-hand for the configuration keys of new(),
    marked with an asterisk (*), they are otherwise the same.
    
    trans() spawns a new instance of MIDI::Trans, this object
    must be used for attribute and configuration methods for
    the operation being performed with trans().  That is to
    say, that if you are using trans(), you must also use the
    trans_obj() method (see below) to return the object operating.
    
    Returns true (1) on success or sets the error() message then
    returns undef otherwise.
    
    The following keys are valid for the hash:
    
        'File'
            The file path to read as the corpus.  This
            key is required.
            
        'Outfile'
            The file to save MIDI output to.
            Default value is './out.midi'
            
        'Delimiter'
            The element delimiter in the corpus.
            Default value is '\s+'
            
        'Tempo'
            The tempo to use for the score,
            you can specify either 'Tempo' or
            'TempoCallBack' keys, but one
            must be specified.  Will override
            the value of 'TempoCallBack'.
            
        'TempoCallBack'
            Subroutine reference, or anonymous
            sub block that will return a tempo
            value.  See CallBacks section below.
            
        'Volume'*
            Subroutine reference, or anonymous
            sub block that will return a valid
            volume value.
            
        'Note'*
            Subroutine reference, or anonymous
            sub block that will return a valid
            note value.

        'Duration'*
            Subroutine reference, or anonymous
            sub block that will return a valid
            duration value.


    USAGE:
    
        if( $TransObj->trans( {
                'File' => './test.txt',
                'Volume' => sub { ... },
                'Note' => sub { ... },
                'Duration' => \&some_sub,
                'Tempo' => 120 } )
                ) {
                # do something
                } else {
                    my $errmsg = $TransObj->error();
                    die("$errmsg\n");
                    }
                    
        OR:
        
        my %hash = (
                'File' => './test.txt',
                'Volume' => sub { ... },
                'Note' => sub { ... },
                'Duration' => \&some_sub,
                'Tempo' => 120
                );
                
        if( $TransObj->trans(\%hash) ) { ... }
        
        Both methods are equivalent.
        

    See the CallBacks section, below, for more information
    about the CallBacks.
    

=head2 THE TRANS_OBJ METHOD

Given that you need to have an active MIDI::Trans object
to use the attribute and information methods, and that
trans() creates a new MIDI::Trans object, the trans_obj()
method has been provided to you for accessing the
usually-needed methods.

trans_obj

    Returns the blessed object being utilized by the
    trans() method, all methods are available to this
    object, but with data specific to the current
    trans() object.
    
    USAGE:

        if( $TransObj->trans( { 'TempoCallBack' => \&tempo, ... } ) ) {
            ...
            }
            
        sub tempo {
            # a callback called from trans()
         my $cur_obj = $TransObj->trans_obj();
         
         my $num_sent = $cur_obj->sentences();
         
         ...
        }
        

        
=head1 CALLBACKS


If MIDI::Trans is like the skeleton for your conversion
application, then the CallBacks you define act as the
nervous system.  The real logic lies in the combination
of information and statistics generated by the corpus, your
use of configurable options, and the callbacks you define.

=head2 PASSING CALLBACKS AS ARGUMENTS

CallBacks must be passed as either references or anonymous
sub blocks.  The following forms are all valid:
(examples use the callback configuration methods)

    $TransObj->volume_callback( sub { ... } );

    --
    
    sub some_sub {
        ...
        }
        
    $TransObj->volume_callback(\&some_sub);

    --
    
    $hashRef->{'key'} = sub { ... };

    $TransObj->volume_callback($hashRef->{'key'});
    
    --
    
    my $sub = sub {
            ...
            };
            
    $TransObj->volume_callback($sub);


=head2 CALLBACK DESCRIPTION

Most CallBacks are passed two arguments:

    The Current Element
    The Current Position
    
The Tempo CallBack is passed no
arguments.

Each CallBack is expected
to return a spefic type and range of data
as a return value.  Each type is discussed
here.  Please note that these are just examples
and in no way reflect the complexity or
interaction available to you.

=head3    Volume CallBacks

    Volume CallBacks return a numeric value to
    represent the absolute volume of the
    current element in a range of 0-127.

    Volume CallBacks are called once
    every element, after Note CallBacks.
    
    Example:
    
    sub VolCallBack {

     my $elem = shift;
     my $enum = shift;

        # in this callback, volume is
        # determined by measuring the
        # length of the input, then
        # comparing that against a
        # constant value, and using that
        # comparison as a multiplier against
        # our maximum volume level.
        
     my $lpct = length($elem) / 24;
     $lpct = 1 if($lpct > 1);
     
        # here, we use the round() method supplied
        # by MIDI::Trans
        
     my $value = $TransObj->round(127 * $lpct);
     
     return($value);
    }
     

=head3  Note CallBacks

    Note CallBacks return a scalar value to
    represent a note or rest event.  The value
    of the event is either a number, in the case
    of a note, or a string - 'rest', in the case
    of a rest event.  For a note event, you
    must specify the absolute value of the
    note as an integer in the range of 0-127.
    For a rest event, simply return a string with
    the value 'rest'.

    Note CallBacks are called once every element.
    They are processed before Volume and Duration.
    
    Example:
    
    sub NoteCallBack {
    
     my $elem = shift;
     my $enum = shift;
     
     my $return;
     
        # here, if the corpus contains
        # an element with the string 'Eighty-
        # Eight', then a note value of 88
        # will be returned, rest otherwise.
        
     if($elem =~ /Eighty-Eight/) {
        $return = 88;
        } else {
            $return = 'rest';
            }

     return($return);
    }


=head3  Duration CallBacks

    Duration CallBacks return a numeric value
    to represent the duration of the current event,
    in quarter notes.  So the actual duration of
    the event, in seconds, is determined by the value of
    the qn_len() configuration method and the tempo
    returned by your Tempo CallBack.
    
    This method is called once every element, after all
    others.

    Example:
    
    sub DurCallBack {
    
     my $elem = shift;
     my $enum = shift;

     return(length($elem));
     
     }
     

=head3  Tempo CallBacks

    Tempo CallBacks return a numeric value
    to represent the number of quarter notes
    per minute to be used in the score.  The
    actual 'tempo' supplied to MIDI::Simple is
    the result of the following equation:
    
    round($base_ms / $tempo);
    
    Where round() is the included round()
    method, $base_ms is the value of the
    configuration attribute base_milliseconds(),
    and $tempo is the tempo returned by your
    Tempo CallBack.
    
    Tempo is called once per processing
    a corpus, before all other CallBacks.

    Please note, that there are no arguments
    to this CallBack, as it is executed BEFORE
    any elements are processed.
    
    Example:
    
    sub TempoCallBack {

     my $num_sents = $TransObj->sentences();
     my $num_words = $TransObj->words();
     
        # this CallBack utilizes Attribute
        # Retrieval methods to determine
        # num of words and sentences in the
        # corpus, then uses these values
        # to form a percentage of a constant
        # maximum tempo.
        
     my $w_to_s_pct = $num_sents / $num_words;
     
     my $max_tempo = 200;
     
     my $tempo = $TransObj->round($max_tempo * $w_to_s_pct);
     
     return($tempo);
    }


=head1 CORPUS ATTRIBUTES

Several Attributes of your corpus may be gleaned
when read.  This is controlled by the 'AllAttributes'
configuration value, set by either new() or the
configuration method all_attributes().  Currently,
those attributes are :

    # of Sentences *
    # of Words *
    # of Elements
    
    (Those marked by an asterisk can be
    turned off to reduce memory consumption)
    
The Sentence Delimiter can be defined as a
configuration value.  The word boundary may not.

=head3  ATTRIBUTE RETRIEVAL METHODS

    The following methods retrive attributes
    about the corpus being processed.  They
    can only be used inside of your CallBacks,
    they are not available elsewhere.
    
    sentences()
    
        Returns the number of sentences
        in the corpus.
        
    words()
    
        Returns the number of words in
        the corpus.
        
    elements()
    
        Returns the number of total elements
        in the corpus.


=head1 METHODS

new HASHREF

    Creates a new instance of the class.  Returns a blessed object
    on success, undef on error.  One argument is allowed, a hash
    reference or anonymous hash, which contains configuration
    information for the object.
    
    The following keys are allowable in the hash, and their values:

    'Raise_Error'
                Boolean, die() on any error with message
                0 = false (default), 1 = true
                      
    'ElementDelimiter'
                Default delimiter used to seperate elements from
                the corpus.  Should be a valid regular expression
                as would fit in (?:).
                Default value is '\s+'
                
    'SentenceDelimiter'
                Default delimiter for end of sentence.  Follows
                same rules as ElementDelimiter.
                Default value is '\.|\?|\!'
                
    'NoteCallBack'
                Default callback for obtaining note values.
                Should be a reference to, or anonymous, sub
                routine.  See the section regarding CallBacks
                above.
                Default value is undef
                
    'VolumeCallBack'
                Default CallBack for obtaining volume values.
                
    'DurationCallBack'
                Default CallBack for obtaining duration values.
                
    'TempoCallBack'
                Default CallBack for obtaining tempo values.
                
    'Channel'
                Default Channel for MIDI output.
                Default value is '1'
                
    'qn_len'
                Default number of ticks per quarter note.
                It is safe to leave this unmodified.
                See MIDI::Simple for more information.
                Default value is '96'
                
    'AllAttributes'
                Boolean, whether or not all attributes of
                the corpus should be measured when reading
                it.  Can be used to lessen memory usage.
                See the Attributes section below for more
                information.
                0 = False, 1 = True (default)
                
    'BaseMilliseconds'
                The base number of ms in a minute.  This
                is used for timing and tempo purposes.
                It is safe to leave this value unmodified.
                Default value is '60000000'
                


    USAGE:
    
        my $TransObj = MIDI::Trans->new( {
                        'VolumeCallBack' => \&vol,
                        'AllAttributes' => 0
                        });
                        

        OR:
        
        
        my %attrs = ( 'AllAttributes' => 1, 'VolumeCallBack' => \&vol );
        
        my $TranObj = MIDI::Trans->new(\%attrs);
        


error()

    Returns the last set error message, or undef if no error
    message has been set.
    

    USAGE:
    
        my $errmsg = $TransObj->error();


        
reset_error()

    Removes the current error message.  Causes error() to return
    undef.  Always returns true (1).
    
    USAGE:
    
        $TransObj->reset_error();


    
trans HASHREF

    The 'wrapper' function for quick use of MIDI::Trans, for more
    information, see the section entitled Plug and Play Usage
    above.
    


trans_obj

    See the section entitled Plug and Play Usage above.
    

read_corpus HASHREF

    Reads, parses, and collects attributes about a given corpus
    (your input data).  The corpus may be specified either as a
    file to read, or a string to parse. Returns true (1) on sucess,
    and sets the error message then returns undef on error.
    
    More than one corpus may be open at a given time.
    
    A single argument must be specified, which is either a hash
    reference or an anonymous hash.  The hash contains information
    about the corpus.  Three keys are possible:
    
        'Name'
            The 'handy' name, or name you wish to
            specify for the corpus.  This is useful
            when opening more than one corpus that
            is a string type.
            If the corpus type is a string, the
            name will default to 'String', otherwise
            the name will default to the file name.
            
        'File'
            When this key is provided, it specifies
            that the corpus type is a file.  This
            key will override the 'String' key,
            even if the value is undef -- resulting
            in an error.  The value for this key
            should be the path to the file you
            want to parse.
            
        'String'
            When this key is provided, it specifies
            that the corpus type is a string.  This
            key is overriden by the 'File' key.  The
            string should be passed as the value.
            
            
    USAGE:
    
        if( $TransObj->read_corpus({ 'File' => './corpus.txt' }) ) {
            ...
            } else {
                my $error = $TransObj->error();
                die("$error\n");
                }

        OR
        
        my %corp_dat = ( 'File' => './corpus.txt', 'Name' => 'Corpus1' );
        
        if( $TransObj->read_corpus(\%corp_dat) ) { ... }
        
        
    NOTE:
    
        The corpus when read, is stored in a list of
        available corpuses(ii?).  This list is ordered,
        in the order they were read, numerically.  This
        is the preferred method for identifying a corpus
        to other methods, but most also accept a Name
        value to identify the corpus, which may be
        easier to track.  The numbering begins at 0.
        
        TODO: Convert all methods to a naming convention.
        
        
        
process HASHREF

    Actually performs processing on a given corpus.  Runs
    all of the callbacks, as needed, either on a per-corpus
    or per-element basis.  Generates the data that will be
    used to create a MIDI score later. Only a single corpus
    may be specified.  Returns true (1) if successful and
    sets the error message then returns undef otherwise.
    
    A single argument must be specified, which is either a hash
    reference or an anonymous hash.  The hash contains information
    identifying the corpus.  There are two keys possible:
    
        'Name'
            The name as given the corpus -- see read_corpus
            above.  Overrides the 'Num' key.  The value should
            be the name of the corpus.
            
        'Num'
            The number of the corpus.  See the NOTE section
            of read_corpus, above.  Is overriden by the 'Name'
            key.
            
            
    USAGE:
    
        if( $TransObj->process( { 'Name' => 'Corpus1' }) ) {
            ..
            } else {
                my $errmsg = $TransObj->error();
                die("$errmsg\n");
                }
                
        OR:
        
        my %corp_dat = ( 'Num' => 1 );
        
        if( $TransObj->process(\%corp_dat) ) { ... }
        


create_score NUM

    Creates a score from the data generated by process(),
    suitable for writing to a file (see write_file() below).
    If the corpus hasn't been parsed, or the processing hasn't
    occured yet, and error will occur.  Returns the
    MIDI::Simple object from the score on success and
    sets the error message then returns undef on failure.
    
    One argument, the identifying number of the corpus
    must be specified.  (See the NOTE section of read_corpus()
    above)
    
    USAGE:
    
        my $scoreObj;
        if( $scoreObj = $TransObj->create_score(0) ) {
            ...
            } else {
                my $errmsg = $TransObj->error();
                die("$errmsg\n");
                }
                


write_file SCORE_OBJECT

    Writes a score to a file, given the score object
    returned from create_score.  Returns true (1) on
    success and sets the error message then returns
    undef on failure.
    
    USAGE:
    
        if( $TransObj->write_file($scoreObj) ) {
            ...
            } else {
                my $errmsg = $TransObj->error();
                die("$errmsg\n");
                }



round DECIMAL

    Returns the nearest rounded integer given
    decimal or integer input.
    
    USAGE:

            # returns 2
            
        my $x = $TransObj->round(1.5);
        
            # returns 1
            
        my $x = $TransObj->round(1.38573927541);
        



=head2 CALLBACK CONFIGURATION METHODS

    These methods allow you to configure the CallBacks
    currently in use by MIDI::Trans, they also allow
    you to retrieve a reference to the CallBack in
    question.  All methods accept an argument of either
    a subroutine reference or anonymous subroutine block.
    All methods return their subref.
    

volume_callback()

    Sets / Returns the callback for volume
    
    USAGE:
    
        my $vol_cb = $TransObj->volume_callback(\&somesub);
        
        
        
note_callback()

    Sets / Returns the callback for notes

    USAGE:

        my $note_cb = $TransObj->note_callback(\&somesub);



duration_callback()

    Sets / Returns the callback for duration

    USAGE:

        my $dur_cb = $TransObj->duration_callback(\&somesub);



tempo_callback()

    Sets / Returns the callback for tempo

    USAGE:

        my $tempo_cb = $TransObj->tempo_callback(\&somesub);



=head2  INFORMATIONAL AND CONFIGURATION METHODS

    These methods, in conjunction with methods such as
    round() (described under the main METHODS heading),
    are useful for modifying the way MIDI::Trans is
    operating, as well as assisting your callbacks in
    performing their operation, and retrieving operating
    values.  All of these (as well as others) may be
    utilized in your CallBacks.  Be careful, however of
    calling process() within a CallBack, as this may
    result in an infinite loop.
    

current_elem()

    Returns the current element from the list of
    elements in the corpus.  This would typically
    be used by your callbacks for determining what
    to generate.
    
    USAGE:
    
        my $element = $TransObj->current_elem();
        


current_pos()

    Returns the position of the current element
    in the document, starting at zero.  That is,
    on the 50th element of the corpus, current_pos()
    would return '49'.
    
    USAGE:

            my $pos = $TransObj->current_pos();
            
            

raise_error()

    Sets, or returns the current value of the
    'Raise_Error' attribute.
    
    USAGE:
    
        my $RE = $TransObj->raise_error(1);
        


delimiter()

    Sets, or returns the current value of the
    'Delimiter' attribute.

    USAGE:

        my $Del = $TransObj->delimiter(1);




sentence_delimiter()

    Sets, or returns the current value of the
    'SentenceDelimiter' attribute.

    USAGE:

        my $SD = $TransObj->sentence_delimiter('\!\?');




all_attributes()

    Sets, or returns the current value of the
    'AllAttributes' attribute.

    USAGE:

        my $AA = $TransObj->all_attributes(1);




channel()

    Sets, or returns the current value of the
    'Channel' attribute.

    USAGE:

        my $Chan = $TransObj->channel(1);




qn_len()

    Sets, or returns the current value of the
    'qn_len' attribute.

    USAGE:

        my $QL = $TransObj->qn_len(1);




tempo()

    Sets, or returns the current value of the
    'Tempo' attribute.  This is usually set
    by your tempo CallBack, but can also
    be set with a default value using the new()
    attribute.  You can use this function to
    override tempo, but this may have little,
    if any, effect on create_events().

    USAGE:

        my $Del = $TransObj->delimiter(1);





=head1 AUTHOR

C. Church <lt>dolljunkie@digitalkoma.com<gt>

=head1 SEE ALSO

L<perl>.

=cut
