package Image::ButtonMaker::Lexicon;
use strict;

my @defaults = (

                 );

my @default_priv = (
                     lexicons => undef,
                     error    => 0,
                     errorstr => undef,
                     binmode  => ':utf8',
                     );

#### Constructor method ########################################
sub new {
    my $invocant = shift;
    my $classname = ref($invocant) || $invocant;

    my $object = {@defaults, @_, @default_priv};
    $object->{lexicons} = {};

    bless $object, $classname;
    return $object;
}


#### Read a lexicon file and return true
##   return undef on error
sub read_lexiconfile {
    my $self = shift;
    my $filename = shift;
    $self->reset_error;

    return $self->set_error(1, "File not found: $filename") 
        unless(-f $filename);

    open INDATA, $filename ||
        return $self->set_error(1, "Could not open file: $filename") ;

    binmode INDATA, $self->{binmode}
      if($self->{binmode});

    my $linenum = 1;

    while(my $line = <INDATA>) {
        ## Comments and blank lines are ignored
        unless($line =~ /^\s*\#/ or $line =~ /^\s*$/) {
            chop $line;
            my @token=split ';', $line;
            if(scalar(@token) != 3) {
                close INDATA;
                return $self->set_error(1, "Invalid data in file $filename, line $linenum:$line") 
            }
            else {
                my $str_id   = $token[0];
                my $str_lang = $token[1];
                my $str_msg  = $token[2];
                $self->{lexicons}{$str_lang}{$str_id} = $str_msg;
            }
        }
        $linenum++;
    }

    close INDATA;
    return 1;
}


sub read_lexiconfiles {
    my $self = shift;
    my @files = @_;
    $self->reset_error;

    foreach my $f (@files) {
        $self->read_lexiconfile($f);
        return undef if($self->{error});
    }
    return 1;
}

sub lookup($$) {
    my $self      = shift;
    my $lang_id   = shift;
    my $string_id = shift;

    return $self->{lexicons}{$lang_id}{$string_id};
}

sub set_error {
    my $self = shift;
    $self->{error}    = shift;
    $self->{errorstr} = shift;
    return shift;
}


sub reset_error {
    my $self = shift;
    $self->{error}    = 0;
    $self->{errorstr} = undef;
    return;
}


sub get_error {
    my $self = shift;
    if($self->{error}) {
        return ($self->{error}, $self->{errorstr}) if(wantarray);
        return $self->{error}.':'.$self->{errorstr};
    }
    return undef;
}

1;

__END__

=head1 NAME

Image::ButtonMaker::Lexicon - lexicon component for Image::ButtonMaker

=head1 DESCRIPTION

This module is for multi-language support for Image::ButtonMaker.

The documentation will write it self...

=head1 AUTHORS

Piotr Czarny <F<picz@sifira.dk>> wrote this module and this crappy
documentation.

=cut
