use strict;
use warnings;

package HTML::SummaryBasic;

our $VERSION = 0.2;

=head1 NAME

HTML::SummaryBasic - Basic summary info from HTML.

=head1 SYNOPSIS

	use HTML::SummaryBasic;
	my $p = new HTML::SummaryBasic  {
		PATH => "input.html",
		# or HTML => '<html>...</html>',
		NOT_AVAILABLE => undef,
	};
	foreach (keys %{$p->{SUMMARY}}){
		warn "$_ ... $p->{SUMMARY}->{$_}\n";
	}

=head1 DEPENDENCIES

	use HTML::TokeParser;
	use HTML::HeadParser;

=cut

use Carp;
use HTML::TokeParser;

=head1 DESCRIPTION

From a file or string of HTML, creates a hash of useful summary information from C<meta> and C<body> elements of an HTML document.

=head1 GLOBAL VARIABLE

=item $NOT_AVAILABLE

Value for empty fields. Default is C<[Not Available]>. May be over-ridden directly by supplying the constructor with a field of the same name.
See L<THE SUMMARY STRUCTURE>.

=cut

our $NOT_AVAILABLE = '[Not available]';

=head1 CONSTRUCTOR (new)

Accepts a hash-like structure...

=over 4

=item HTML or PATH

Ref to a scalar of HTML, or plain string that is the path to an HTML file to process.

=item SUMMARY

Filled after C<get_summary> is called (see L<METHOD get_summary> and
L<THE SUMMARY STRUCTURE>).

=item FIELDS

An array of C<meta> tag C<name>s whose C<content> value should be
placed into the respective slots of the C<SUMMARY> field after
C<get_summary> has been called.

=back

=head2 THE SUMMARY STRUCTURE

A field of the object which is a hash, with key/values as follows:

=over 4

=item AUTHOR

HTML C<meta> tag C<X-META-AUTHOR>.

=item TITLE

Text of the element of the same name.

=item DESCRIPTION

Content of the C<meta> tag named C<X-META-DESCRIPTION>.

=item LAST_MODIFIED_META, LAST_MODIFIED_FILE

Time since of the modification of the file,
respectively according to any C<meta> tag of the same name,
with a C<X-META-> prefix; failing that, according to the file system. 

=item CREATED_META, CREATED_FILE

As above, but relating to the creation date of the file.

=item FIRST_PARA

The first HTML C<p> element of the document.

=item HEADLINE

The first C<h1> tag; failing that, the first C<h2>; failing that,
the value of C<$NOT_AVAILABLE>.

=item PLUS...

Any meta-fields specified in the C<FIELDS> field.

=back

=cut

sub new { 
	my $class = shift;
	$class = ref($class)? ref($class) : $class;
	my $self = bless {}, $class;
	my $args = ref($_[0])? shift : {@_};
	
	# Defaults
	$self->{SUMMARY}	= {};
	
	# Load parameters
	$self->{uc $_} = $args->{$_} foreach keys %$args;
	croak "Required parameter field missing : $_" if not $self->{PATH};

	$self->_get_summary();
	return $self;
}


sub _get_summary { 
	my ($self,$path) = @_;
	
	my ($p,$token, $html);
	
	if (defined $path){
		if (ref $path){
			$html = $path;
			delete $self->{PATH};
		} else {
			$self->{PATH} = $path;
		}
	} 

	if ($self->{PATH}){
		$html = $self->_load_file() 
			or return undef;
	}
	
	# Get first para
	if (not $p = new HTML::TokeParser( $html ) ){
		warn "HTML::TokeParser could not initiate: $!";
		return undef;
	}
	if ($token = $p->get_tag('h1')){
		$self->{SUMMARY}->{HEADLINE} = $p->get_trimmed_text;
	} else {
		$p = new HTML::TokeParser( $html );
		if ($token = $p->get_tag('h2')){
			$self->{SUMMARY}->{HEADLINE} = $p->get_trimmed_text;
		} else {
			$self->{SUMMARY}->{HEADLINE} = $self->{NOT_AVAILABLE};
		}
	}
	if (not $p = new HTML::TokeParser( $html ) ){
		warn "HTML::TokeParser could not initiate: $!";
		return undef;
	}
	if ($token = $p->get_tag('p')){
		$self->{SUMMARY}->{FIRST_PARA} = $p->get_trimmed_text;
	} else {
		$self->{SUMMARY}->{FIRST_PARA} = $self->{NOT_AVAILABLE}
	}
	
	$p = new HTML::TokeParser( $html );
	$p->get_tag('title');
	$self->{SUMMARY}->{TITLE} = $p->get_text('/title') || $self->{NOT_AVAILABLE};

	{
		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
		   $atime,$mtime,$ctime,$blksize,$blocks) = stat $self->{PATH};

		$self->{SUMMARY}->{LAST_MODIFIED_FILE} = scalar localtime ( $mtime ) || $self->{NOT_AVAILABLE};
		$self->{SUMMARY}->{LAST_MODIFIED_FILE} =~ s/\s+/ /g;

		$self->{SUMMARY}->{CREATED_FILE} = scalar localtime ( $ctime ) || $self->{NOT_AVAILABLE};
		$self->{SUMMARY}->{CREATED_FILE} =~ s/\s+/ /g;
	}

	my $collect = {
		map {$_=>1} (
			keys %{$self->{FIELDS}},
			qw(
				AUTHOR DESCRIPTION 
				LAST-MODIFIED CREATED
			)
		)
	};
	
	$self->{SUMMARY}->{$_} = $self->{NOT_AVAILABLE} foreach keys %$collect;
	
	$p = new HTML::TokeParser( $html );
	while (my $tag = $p->get_tag('meta') ){
		my $name = uc $tag->[1]->{name};
		I:
		for my $i (1..2){
			$name =~ s/^X-META-//i if $i == 2;
			if (exists $collect->{$name} ){
				$self->{SUMMARY}->{$name} = $tag->[1]->{content};
				last I;
			}
		}
	}

	$self->{SUMMARY}->{LAST_MODIFIED_META} = delete $self->{SUMMARY}->{"LAST-MODIFIED"};
	$self->{SUMMARY}->{CREATED_META} = delete $self->{SUMMARY}->{"CREATED"};

	return 1;
}


#  Return a reference to a scalar of HTML, or C<undef> on failure, setting C<$!> with an error message.

sub _load_file { 
	my ($self,$path) = @_;
	local *IN;
	return $path if ref $path;
	
	if (defined $path){
		$self->{PATH} = $path
	}
	elsif (not $self->{PATH}){
		warn "load_file requires a path argument, or that the PATH field be set";
		return undef;
	}
	if (not open IN, $self->{PATH}){
		warn "load_file could not open $self->{PATH}";
		return undef;
	}
	read IN, $_, -s IN;
	close IN;
	return \$_;
}

1;

=head1 TODO

Maybe work on URI as well as file paths.

=head1 SEE ALSO

L<HTML::TokeParser>, L<HTML::HeadParser>.

=head1 AUTHOR

Lee Goddard (LGoddard@CPAN.org)

=head1 COPYRIGHT

Copyright 2000-2001 Lee Goddard.

This library is free software; you may use and redistribute it or modify it
undef the same terms as Perl itself.



