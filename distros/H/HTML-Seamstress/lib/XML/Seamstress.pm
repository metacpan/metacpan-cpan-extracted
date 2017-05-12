package XML::Seamstress;
 
use Set::Array;
use Data::Dumper;

use 5.006;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = sprintf '%2d.%02d', q$Revision: 3.0 $ =~ /(\d+)\.(\d+)/;


# Preloaded methods go here.

sub new {
    my ($that, %config) = @_;
    my $class = ref( $that ) || $that;
    my $this = \%config;

    return bless $this, $class;
}

sub __locate {
    my ($self, $file) = @_;

#    warn "self", Data::Dumper::Dumper($self);

    my @dir = split /\s+/, $self->{incl} ;
#    warn "searching @dir for $file";
    for my $dir (@dir) {
	my $f = "$dir/$file";
	return $f if (-e $f);
    }
    return undef;
}

sub __store_ref {
  my ($self, $data) = @_;

  my ($caller) = ((caller(1))[3] =~ /:(\w+)$/);
#  warn "storing $data in self $caller";

  $self->{$caller} = $data;
}


sub __escape_text {
	my @a = @_;
	for ( @a ) {
		s/&/&amp;/g;
		s/"/&quot;/g;
		s/</&lt;/g;
		s/>/&gt;/g;
	}
	return @a > 1 ? @a : $a[0];
}

  

sub _check_key {
	my ($this, $node, $is_end_tag, $key) = @_;
	return 0 if $is_end_tag;

	$node->attr( 'checked', $this->{$key} ? 'checked' : undef );
	return 1;
}

sub _select_key {
	my( $this, $node, $class, $is_end_tag ) = @_;
	return 0 if $is_end_tag;
	my( $key ) = $class =~ /^select::(\w+)$/;
	$node->attr( 'selected',
		$node->attr( 'value' ) eq $this->{ $key } ? 'selected' : undef
	);
	return 1;

}

sub _append_attr {
	my ($this, $node, $is_end_tag, $attr, $key ) = @_;
	return 0 if $is_end_tag;

	my $current_value = $node->attr($attr);
	$current_value .= __escape_text($this->{$key});
	$node->attr( $attr, $current_value);
	return 1;
}


sub sub_att {
	my( $this, $node, $class, $is_end_tag ) = @_;
	return 0 if $is_end_tag;
	my( $att, $key ) = $class =~ /^sub::(\w+)::(\w+)$/;
	$node->attr( $att, __escape_text( $this->{ $key } ) );
	return 1;
}


sub sub_href {
	my( $this, $node, $class, $is_end_tag ) = @_;
	return 0 if $is_end_tag;
	my( $key ) = $class =~ /^href::(\w+)$/;
	$node->attr( 'href', __escape_text( $this->{ $key } ) );
	return 1;
}

sub href_id {
	my( $this, $node, $class, $is_end_tag ) = @_;
	return 0 if $is_end_tag;
	my( $key ) = $class =~ /^href_id::(\w+)$/;
	$node->atts->{ href } =~ s/\d+/__escape_text( $this->{ $key } )/e;
	return 1;
}

sub _text {
    my ($self,$text) = @_;
#    die "_TEXT($self,$text);";
#    $self->{node}->splice_content(0, 1, __escape_text($text));
    $self->{node}->splice_content(0, 1, $text);
}

sub _value {
    my ($self,$value) = @_;
#    die "_TEXT($self,$text);";
#    $self->{node}->splice_content(0, 1, __escape_text($text));
    $self->{node}->attr('value', $value);
}

sub _aref { 
    my ($self, $aref) = @_;
    
    warn "AREF: ", Data::Dumper::Dumper(\@_);

    my $r = Set::Array->new(@$aref);
}

    

sub _include {
    my ($this, $node, $is_end_tag, $filename, $escape) = @_;
    return 0 if $is_end_tag;

    my $file = $this->__locate($filename);
#    warn "seamstress found $file";
    open F, $file or die "couldnt open $file: $!";
    my $content = join '', <F>;
#    warn "content: $content";
    
    $content = escape_text($content) if $escape;

    $node->splice_content(0, 1, $content);
}


1;
__END__

=head1 NAME

XML::Seamstress - 

=head1 AUTHOR

T.M. Brannon <tbone@cpan.org>

=cut

