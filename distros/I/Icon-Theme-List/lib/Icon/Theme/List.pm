package Icon::Theme::List;

use warnings;
use strict;

=head1 NAME

Icon::Theme::List - Lists installed icon themes.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Icon::Theme::List;

    my $iconlist = Icon::Theme::List->new();

=head1 FUNCTIONS

=head2 new

This initiates it.

One object is accepted and it is a hash reference.

=head3 args hash

=head4 dir

This dir to use instead of trying to find it automatically.

If this is not specified, the locations below will be checked.

    /usr/local/share/icons/
    /usr/share/icons/

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $function='new';

	#create the object
	my $self={error=>undef, errorString=>'', module=>'Icon-Theme-List', perror=>undef};
	bless $self;

	#if it is not specified check if the two common locations exists
	if (!defined($args{dir})) {
		if (-d '/usr/local/share/icons/') {
			$args{dir}='/usr/local/share/icons/';
		}else {
			if ( -d '/usr/share/icons/') {
				$args{dir}='/usr/local/share/icons/';
			}
		}
	}

	#makes sure we have one
	if (!defined($args{dir})) {
		$self->{error}=1;
		$self->{perror}=1;
		$self->{errorString}='No icon theme directory specified and one could not be located';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#make sure it is really a directory
	if (! -d $args{dir}) {
		$self->{error}=2;
		$self->{perror}=1;
		$self->{errorString}='"'.$args{dir}.'" is not a directory';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#saves it for later usage
	$self->{dir}=$args{dir};

	return $self;
}

=head2 check

This checks if the specified theme is present.

One arguement is required and that is the name of the theme
to check to see if it is present.

A return value of true means it is present.

    my $returned=$iconlist->check('hicolor');
    if( $iconlist->{error} ){
        print "Error!\n";
    }else{
        if( $returned ){
            print "It is present.\n";
        }
    }

=cut

sub check{
	my $self=$_[0];
	my $theme=$_[1];
	my $function='list';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	#make sure a theme was specified
	if (!defined($theme)) {
		$self->{error}=3;
		$self->{errorString}='No theme specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#gets the list
	my @themes=$self->list;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': list errored');
		return undef;
	}

	#checks for a match
	my $int=0;
	while (defined( $themes[$int] )) {
		if ($themes[$int] eq $theme) {
			return 1;
		}

		$int++;
	}

	return undef;
}

=head2 list

This lists the available icon themes.

The returned value is a array.

    my @themes=$iconlist->list;
    if($iconlist->{error}){
        print "Error!\n";
    }

=cut

sub list{
	my $self=$_[0];
	my $function='list';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	opendir(LIST, $self->{dir});
	my @themes=grep(!/\./, readdir(LIST) );
	closedir(LIST);
	
	return @themes;
}

=head2 errorblank

This is a internal that blanks any previous errors.

=cut

sub errorblank{
	my $self=$_[0];
	
	if ($self->{perror}) {
		return undef;
	}

	$self->{error}=undef;
	$self->{errorString}="";
	
	return 1;
};


=head1 ERROR CODES

The current error code can be found by checking $iconlist->{error}. If it is true,
a error is present. A more verbose description can be found by checking
$iconlist->{errorString}.

If $iconlist->{perror} is true, then it means that a permanent error is set.

=head2 1

No dir specified and one could not be located.

This means that the locations listed below don't exist.

    /usr/local/share/icons/
    /usr/share/icons/

=head2 2

The specified icon directory is actually not a directory.

=head2 3

No theme specified.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-icon-theme-list at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Icon-Theme-List>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Icon::Theme::List


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Icon-Theme-List>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Icon-Theme-List>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Icon-Theme-List>

=item * Search CPAN

L<http://search.cpan.org/dist/Icon-Theme-List/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Icon::Theme::List
