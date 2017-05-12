package Fuse::TagLayer::PurePerl;

use Data::Dumper;

use Exporter;
push @Fuse::TagLayer::PurePerl::ISA, 'Exporter';
our @EXPORT = ('db_init','db_sync','db_disconnect','db_tags_add','db_tags_all','db_files_add','db_files_for_tags');

our %hash; # files by tag, HoA
our %tags; # tags by file, HoH
our @all;
our $opts;

sub db_init {
	$opts = { @_ };
}

sub db_sync { 1; }

sub db_disconnect {
	%hash = ();
	%tags = ();
	@all = ();
}

sub db_tags_add { 1; }

sub db_tags_all {
	unless(@all){ @all = keys %hash };
	return \@all;
}

sub db_files_add {
	my ($dir,$basename,@tags) = @_;

	print "##  PurePerl::db_files_add: dir:$dir, basename:$basename, tags:@tags\n" if $opts->{debug} > 2;

	for(@tags){
	#	%{ ${ $hash{$_} }[0] } = map { $_ => 1 } @tags;

		%{ $tags{ $dir.'/'.$basename } } = map { $_ => 1 } @tags;

		push( @{ $hash{$_} }, $dir.'/'.$basename );
	}
}

## returns:
## ref to a list of files tagged with input tags, and
## ref to a hash of subtags (all tags associated with returned files, minus the input tags)
sub db_files_for_tags {
	my (@tags) = @_;

	my @oktags;
	for(@tags){
		push(@oktags, $_) if defined $hash{ $_ };
	}
	unless(@oktags){
		print "##  PurePerl::db_files_for_tags: @tags ; no files\n" if $opts->{debug};
		return ([],{})
	}
	@tags = @oktags;
	print "##  PurePerl::db_files_for_tags: @tags\n" if $opts->{debug};

	# gather files
	my @files_for_tags;
	my %file_hash;
	for my $tag (@tags){
		for(@{ $hash{ $tag } }){
			$file_hash{ $_ }++;
		}
	}
	@files_for_tags = keys %file_hash;

	# gather tags
	my %subtags;
	for my $file ( @files_for_tags ){
		for( keys %{ $tags{ $file } } ){
			$subtags{$_}++;
		}
	}

	print "##  PurePerl::db_files_for_tags: ".scalar(@files_for_tags)." files ; ".scalar(keys(%subtags))." subtags (before minus)\n" if $opts->{debug} > 1;

	for(@tags){ delete($subtags{$_}); }

	return (\@files_for_tags, \%subtags);
}

1;
