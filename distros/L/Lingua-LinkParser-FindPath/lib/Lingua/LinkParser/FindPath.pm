package Lingua::LinkParser::FindPath;


use strict;

our $VERSION = '0.01';

use fields qw(parser sentence);
use Lingua::LinkParser;
sub new {
    my $class = shift;
    my %arg = @_;
    if( ! ref $arg{parser} ){
        require Lingua::LinkParser;
        $arg{parser} = Lingua::LinkParser->new;
    }
    bless { parser => $arg{parser}, sentence => undef } => $class;
}

sub sentence {
    my $self = shift;
    $self->{sentence} = ref $_[0] ? shift : $self->{parser}->create_sentence(shift);
    return $self;
}

sub clean_word {
    $_[0] =~ s/(\[.\])?\..$//o;
    $_[0];
}


sub find_start {
    my $linkage = shift;
    my $pattern = shift;
    foreach ($linkage->words){
	my $text = $_->text;
	next if $text eq 'LEFT-WALL' || $text eq 'RIGHT-WALL';
	$text = clean_word $text;
#	print $text,$/;
	if($text eq $pattern){
	    return $_;
	}
    }
}

sub sig {
    local $_ = shift;
    if(ref($_) =~ /link$/i){
	my $w = clean_word $_->linkword();
	return $_->linkposition().':'.$w
    }
    else {
	my $w = clean_word $_->text();
	return $_->position().':'.$w
    }
}



sub find {
    my $self = shift;
    my ($start, $stop) = @_;
    my $linkage = ($self->{sentence}->linkages)[0];
#    print $self->{parser}->get_diagram($linkage);
    my $found;
    my @path;
    my @stack;
    my $link;
    my $cur_ptr;
    my $start = find_start($linkage, $start);
    return unless ref $start;
    push @stack, $start;
    my %visited_word;
    while(@stack and not $found){
	if(not $cur_ptr){
	    $cur_ptr = $stack[-1];
#	    print "LINKS ", Dumper $cur_ptr;
	    $visited_word{$cur_ptr->position.':'.$cur_ptr->text} = 1;
	    push @{$link->{sig $cur_ptr}}, $cur_ptr->links;
	    push @path, $cur_ptr->text;
	}
	elsif($cur_ptr){
	    if(my $next_ptr = shift @{$link->{sig $cur_ptr}}){
		######################################################################
		# Find label
		######################################################################
		next if $next_ptr->linkword eq 'LEFT-WALL' || $next_ptr->linkword eq 'RIGHT-WALL';
		push @path, $next_ptr->linklabel;
		my $linkword = $next_ptr->linkword;
#		print "WORDS ", Dumper $next_ptr;
		$linkword = clean_word $linkword;
#		print $next_ptr->linkposition.':'.$linkword,$/;
		$visited_word{$next_ptr->linkposition.':'.$linkword} = 1;
		push(@path, $linkword)&&last if $linkword eq $stop;

		######################################################################
		# Find word
		######################################################################
		$next_ptr = $linkage->word($next_ptr->linkposition);
		push @stack, $next_ptr;
		my @links = $next_ptr->links;
#		print Dumper \%visited_word;
		@links =grep {!$visited_word{sig $_}} @links;
#		print "LINKS ", Dumper \@links;
		$cur_ptr = $stack[-1];
		push @{$link->{sig $cur_ptr}}, @links;
		push @path, $cur_ptr->text;
	    }
	    else {
		pop @stack;
		if(@path > 1){
		    pop @path;
		    pop @path;
		}
		$cur_ptr = $stack[-1];
	    }
	}
	if(!@stack){
	    last;
	}
    }
    foreach my $i (reverse 1..$#path){
	if($path[$i] eq $path[0]){
	    undef $path[$_] for 0..$i-1;
	}
    }

    @path = grep{$_} @path;
    print Dumper \@path;
#    @path = map{ clean_word $_} @path;
    @path;
}

sub find_as_string {
    my $self = shift;
    my $t = 0;
    join q/ /, map{(++$t)%2 ? $_ : "<$_>"} $self->find(@_);
}


1;
__END__

=pod

=head1 NAME

Lingua::LinkParser::FindPath - Find paths in diagrams generated by Link Grammar Parser

=head1 SYNOPSIS

    use Data::Dumper;
    use Lingua::LinkParser::FindPath;
    my $f = new Lingua::LinkParser::FindPath;
    $f->sentence('John sees a girl in the park with a telescope');

    print $f->get_diagram;

    print Dumper [ $f->find('John' => 'telescope') ];

    print $f->find_as_string('John' => 'telescope'),$/;
 
=head1 DESCRIPTION

This module helps you to find a path linking from one word to another
word in diagrams generated by Link Grammar Parser.

See also L<Lingua::LinkParser> and L<Lingua::LinkParser::MatchPath>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Yung-chung Lin (a.k.a. xern) E<lt>xern@cpan.orgE<gt>

This library is free software; Redistribution and/or modification
under the same terms as Perl itself is allowed.

=cut
