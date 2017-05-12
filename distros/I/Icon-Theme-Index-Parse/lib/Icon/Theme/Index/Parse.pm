package Icon::Theme::Index::Parse;

use warnings;
use strict;
use Config::IniHash;

=head1 NAME

Icon::Theme::Index::Parse - Parse the index file for Freedesktop compatible icon themes.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

Information for index file specification can be found at the URL below.

http://standards.freedesktop.org/icon-theme-spec/icon-theme-spec-latest.html

    use Icon::Theme::Index::Parse;

    my $themeindex = Icon::Theme::Index::Parse->new_from_file('/usr/local/share/icons/hicolor/index.theme');
    if($themeindex->{error}){
        print "Error!\n";
    }

=head1 METHOD

=head2 new_from_data

This forms a new object from the raw data.

One arguement is accepted and it is the raw data from a
index file.

    my $themeindex=Icon::Theme::Index::Parse->new_from_data($data);
    if($themeindex->{error}){
        print "Error!\n";
    }

=cut

sub new_from_data{
	my $data=$_[1];
	my $method='new_from_data';

	#init the object
	my $self={ error=>undef, errorString=>'', perror=>undef, module=>'Icon-Theme-Index-Parse' };
	bless $self;
	
	#make sure a file is specified
	if (!defined( $data )) {
		$self->{error}=4;
		$self->{errorString}='No data specified';
		$self->{perror}=1;
		warm($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	$self->{ini}=ReadINI(\$data, case=>'preserve' );

	return $self;
}

=head2 new_from_file

This creates a new object from the specified
index file.

One arguement is accepted and it is the path to the
file.

    my $themeindex=Icon::Theme::Index::Parse->new_from_file('/usr/local/share/icons/hicolor/index.theme');
    if($themeindex->{error}){
        print "Error!\n";
    }

=cut

sub new_from_file{
	my $file=$_[1];
	my $method='new_from_file';

	#init the object
	my $self={ error=>undef, errorString=>'', perror=>undef, module=>'Icon-Theme-Index-Parse' };
	bless $self;
	
	#make sure a file is specified
	if (!defined( $file )) {
		$self->{error}=1;
		$self->{errorString}='No file specified';
		$self->{perror}=1;
		warm($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#make sure it exists
	if (!-f $file) {
		$self->{error}=2;
		$self->{errorString}='The specified file does not exist';
		$self->{perror}=1;
		warm($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#opens the file
	my $data;
	if ( open(INDEXFILE, $file) ) {
		$data=join('', <INDEXFILE>);
		close(INDEXFILE);
	}else {
		$self->{error}=3;
		$self->{errorString}='No file specified';
		$self->{perror}=1;
		warm($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;		
	}

	$self->{ini}=ReadINI(\$data, case=>'preserve' );

	return $self;
}

=head2 comment

This fetches a description for the theme.

If the comment setting is not defined 'false' is
returned.

    my $hidden=$themeindex->hidden;

=cut

sub comment{
	my $self=$_[0];
	my $method='comment';

	if (!$self->errorblank) {
 		warn($self->{module}.' '.$method.': A parmanent error is set');
	}

	#makes sure it is defined
	if (!defined( $self->{ini}{'Icon Theme'}{Comment} )) {
		return undef;
	}

	return $self->{ini}{'Icon Theme'}{Comment};
}

=head2 directories

This gets a list of directories for the theme.

    my @directories=$themeindex->directories;

=cut

sub directories{
	my $self=$_[0];
	my $method='directories';

	if (!$self->errorblank) {
		warn($self->{module}.' '.$method.': A parmanent error is set');
	}

	#split the directories apart at the
	my @directories=split(/\,/, $self->{ini}{'Icon Theme'}{Directories});

	return @directories;
}

=head2 dirContext

This gets the context for icons in the directory.

    my $context=$themeindex->dirContext('48x48/mimetypes');

=cut

sub dirContext{
	my $self=$_[0];
	my $dir=$_[1];
	my $method='dirContext';

	if (!$self->errorblank) {
		warn($self->{module}.' '.$method.': A parmanent error is set');
	}

	#make sure the user specified a directory
	if (!defined( $dir )) {
		$self->{error}=5;
		$self->{errorString}='No directory specified.';
		$self->{perror}=1;
		warm($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#make sure the directory exists
	if (!defined( $self->{ini}{$dir} )) {
		$self->{error}=6;
		$self->{errorString}='The directory "'.$dir.'" does not exist';
		$self->{perror}=1;
		warm($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#return undef if there is no contect
	if (!defined( $self->{ini}{$dir}{Context} )) {
		return undef;
	}

	return $self->{ini}{$dir}{Context};
}

=head2 dirExists

This checks if the specified directory exists in the index.

    my $returned=$themeindex->dirExists('48x48/mimetypes');
    if($returned){
        print "It exists.\n";
    }

=cut

sub dirExists{
	my $self=$_[0];
	my $dir=$_[1];
	my $method='directories';

	if (!$self->errorblank) {
		warn($self->{module}.' '.$method.': A parmanent error is set');
	}

	if (defined( $self->{ini}{'Icon Theme'}{$dir} )) {
		return 1;
	}

	return 0;
}

=head2 dirMaxSize

This gets the maximum size for icons in the directory.

    my $maxsize=$themeindex->dirMaxSize('48x48/mimetypes');

=cut

sub dirMaxSize{
	my $self=$_[0];
	my $dir=$_[1];
	my $method='dirMaxSize';

	if (!$self->errorblank) {
		warn($self->{module}.' '.$method.': A parmanent error is set');
	}

	#make sure the user specified a directory
	if (!defined( $dir )) {
		$self->{error}=5;
		$self->{errorString}='No directory specified.';
		$self->{perror}=1;
		warm($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#make sure the specified dir info exists
	if (!defined( $self->{ini}{$dir} )) {
		$self->{error}=6;
		$self->{errorString}='The directory "'.$dir.'" does not exist';
		$self->{perror}=1;
		warm($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#return undef if none is specified
	if (!defined( $self->{ini}{$dir}{MaxSize} )) {
		return undef;
	}

	return $self->{ini}{$dir}{MaxSize};
}

=head2 dirMinSize

This gets the minimum size for icons in the directory.

    my $minsize=$themeindex->dirMinSize('48x48/mimetypes');

=cut

sub dirMinSize{
	my $self=$_[0];
	my $dir=$_[1];
	my $method='dirMinSize';

	if (!$self->errorblank) {
		warn($self->{module}.' '.$method.': A parmanent error is set');
	}

	#error if the user did not specifiy a directory
	if (!defined( $dir )) {
		$self->{error}=5;
		$self->{errorString}='No directory specified.';
		$self->{perror}=1;
		warm($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#error if the dir queried does not exist
	if (!defined( $self->{ini}{$dir} )) {
		$self->{error}=6;
		$self->{errorString}='The directory "'.$dir.'" does not exist';
		$self->{perror}=1;
		warm($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#return undef if none is specified
	if (!defined( $self->{ini}{$dir}{MinSize} )) {
		return undef;
	}

	return $self->{ini}{$dir}{MinSize};
}

=head2 dirSize

This gets the nominal size for icons in the directory.

    my $size=$themeindex->dirSize('48x48/mimetypes');

=cut

sub dirSize{
	my $self=$_[0];
	my $dir=$_[1];
	my $method='dirSize';

	if (!$self->errorblank) {
		warn($self->{module}.' '.$method.': A parmanent error is set');
	}

	#error if the user did not specify a dir to query
	if (!defined( $dir )) {
		$self->{error}=5;
		$self->{errorString}='No directory specified.';
		$self->{perror}=1;
		warm($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#error if there is no directory specified
	if (!defined( $self->{ini}{$dir} )) {
		$self->{error}=6;
		$self->{errorString}='The directory "'.$dir.'" does not exist';
		$self->{perror}=1;
		warm($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#return undef if none is specified
	if (!defined( $self->{ini}{$dir}{Size} )) {
		return undef;
	}

	return $self->{ini}{$dir}{Size};
}

=head2 dirThreshold

The icons in this directory can be used if the size
differ at most this much from the desired size.

Returns 2 if not present.

    my $threshold=$themeindex->dirThreshold('48x48/mimetypes');

=cut

sub dirThreshold{
	my $self=$_[0];
	my $dir=$_[1];
	my $method='dirType';

	if (!$self->errorblank) {
		warn($self->{module}.' '.$method.': A parmanent error is set');
	}

	#make sure the user specified a directory
	if (!defined( $dir )) {
		$self->{error}=5;
		$self->{errorString}='No directory specified';
		$self->{perror}=1;
		warm($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure the dir info exists
	if (!defined( $self->{ini}{$dir} )) {
		$self->{error}=6;
		$self->{errorString}='The directory "'.$dir.'" does not exist';
		$self->{perror}=1;
		warm($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#return 2 as per the spec if this is not defined
	if (!defined( $self->{ini}{$dir}{Threshold} )) {
		return '2';
	}

	return $self->{ini}{$dir}{Threshold};
}

=head2 dirType

This gets the type of icon size for icons in the directory.

    my $type=$themeindex->dirType('48x48/mimetypes');

=cut

sub dirType{
	my $self=$_[0];
	my $dir=$_[1];
	my $method='dirType';

	if (!$self->errorblank) {
		warn($self->{module}.' '.$method.': A parmanent error is set');
	}

	#make sure it is specified
	if (!defined( $dir )) {
		$self->{error}=5;
		$self->{errorString}='No directory specified.';
		$self->{perror}=1;
		warm($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#makes sure the directory exists
	if (!defined( $self->{ini}{$dir} )) {
		$self->{error}=6;
		$self->{errorString}='The directory "'.$dir.'" does not exist';
		$self->{perror}=1;
		warm($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#return undef if no type is specified
	if (!defined( $self->{ini}{$dir}{Type} )) {
		return undef;
	}

	return $self->{ini}{$dir}{Type};
}

=head2 example

This fetches a icon to use for a example for the theme.

If the comment setting is not defined 'false' is
returned.

    my $example=$themeindex->example;

=cut

sub example{
	my $self=$_[0];
	my $method='example';

	if (!$self->errorblank) {
		warn($self->{module}.' '.$method.': A parmanent error is set');
	}

	#makes sure it is defined
	if (!defined( $self->{ini}{'Icon Theme'}{Example} )) {
		return undef;
	}

	return $self->{ini}{'Icon Theme'}{Comment};
}

=head2 hidden

This gets if a it should be displayed or note.

The value returned should most likely match /[Ff][Aa][Ll][Ss][Ee]/
or /[Tt][Rr][Uu][Ee]/.

If the hidden setting is not defined 'false' is
returned.

    my $hidden=$themeindex->hidden;

=cut

sub hidden{
	my $self=$_[0];
	my $method='hidden';

	if (!$self->errorblank) {
		warn($self->{module}.' '.$method.': A parmanent error is set');
	}

	#makes sure it is defined
	if (!defined( $self->{ini}{'Icon Theme'}{Hidden} )) {
		return undef;
	}

	return $self->{ini}{'Icon Theme'}{Hidden};
}

=head2 inherits

This gets a list of themes the theme inherits from.

    my @dinherits=$themeindex->inherits;

=cut

sub inherits{
	my $self=$_[0];
	my $method='inherits';

	if (!$self->errorblank) {
		warn($self->{module}.' '.$method.': A parmanent error is set');
	}

	#what will be returned
	my @inherits;
	
	#split the directories apart at the
	if (defined( $self->{ini}{'Icon Theme'}{Inherits} )) {
		@inherits=split(/\,/, $self->{ini}{'Icon Theme'}{Inherits});
	}

	#use Data::Dumper;
	#print Dumper($self);

	return @inherits;
}

=head2 name

This fetches a name for the theme.

If the comment setting is not defined 'false' is
returned.

    my $name=$themeindex->name;

=cut

sub name{
	my $self=$_[0];
	my $method='name';

	if (!$self->errorblank) {
		warn($self->{module}.' '.$method.': A parmanent error is set');
	}

	#makes sure it is defined
	if (!defined( $self->{ini}{'Icon Theme'}{Name} )) {
		return undef;
	}

	return $self->{ini}{'Icon Theme'}{Name};
}

=head2 errorblank

This is a internal function that blanks any previous errors.

=cut

sub errorblank{
	my $self=$_[0];

	if ($self->{perror}) {
		return undef;
	}

	$self->{error}=undef;
	$self->{errorString}=undef;

	return 1;
}

=head1 ERROR CODES

=head2 1

No file name specified.

=head2 2

The file does not exist.

=head2 3

Failed to open the index file.

=head2 4

No data specified.

=head2 5

No directory specified.

=head2 6

The dir queries does not exist.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-icon-theme-index-parse at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Icon-Theme-Index-Parse>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Icon::Theme::Index::Parse


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Icon-Theme-Index-Parse>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Icon-Theme-Index-Parse>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Icon-Theme-Index-Parse>

=item * Search CPAN

L<http://search.cpan.org/dist/Icon-Theme-Index-Parse/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Icon::Theme::Index::Parse
