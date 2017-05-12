package ContentOfRandomFileTestOptions;
use base qw/RandomFileMethodAllTests/;

use strict;
use warnings;

use File::Random;

sub _no_cvs_subdir_check($);
sub _guess_filename(@);

# Replace random_file with calling content_of_random_file
# Analyze the content and return the file name because of the analysis
sub random_file {
	my ($self, %args) = @_;
	my @content = $self->content_of_random_file(
		%args,
		(exists($args{-check}) and (ref($args{-check}) !~ /CODE|Regexp/))
			? ()    # -check option without a sensful value, should surely fail
			: (-check => _no_cvs_subdir_check $args{-check})
	);
	return _guess_filename @content;
}

sub _no_cvs_subdir_check($) {
	my $check = shift() || sub {"no checking done - always true"};
	return sub {
		return 0 if /CVS/;   # filename seems to be in a CVS subdir
		ref($check) eq 'Regexp' ? return /$check/ : return $check->(@_)
	};
}

# In the fileX files there's only one line "Content: fileX"
# In the [xyz].dat files there are some lines, the 4th line contains the fname
sub _guess_filename(@) {
	$_[0] and $_[0] =~ /^Content: (.*)$/          and return $1;
	$_[3] and chomp($_[3]),$_[3] =~ /^(\w\.dat)$/ and return $1;
	return undef;
}

1;
