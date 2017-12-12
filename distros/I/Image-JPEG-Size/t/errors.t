#! perl

use strict;
use warnings;

use Test::More;

use Image::JPEG::Size;

my $invalid = 't/data/invalid.jpg';
my $recoverable = 't/data/recoverable.jpg';
my $dupe_errors = 't/data/duplicate-errors.jpg';

my $invalid_error = 'Invalid JPEG file structure: missing SOS marker';
my $invalid_warning =
    'Corrupt JPEG data: 764 extraneous bytes before marker 0xd9';

my @recoverable_warnings = (
    'Corrupt JPEG data: 40 extraneous bytes before marker 0xfe',
    'Corrupt JPEG data: 52 extraneous bytes before marker 0xc4',
);

my @deduped_warnings = (
    'Premature end of JPEG file',
    'Corrupt JPEG data: 1 extraneous bytes before marker 0xd9',
    'Invalid JPEG file structure: missing SOS marker',
);

sub clean {
    my ($s) = @_;
    $s =~ s{ at t/errors\.t line [0-9]+\.?\n?\z}{}ms;
    return $s;
}

sub catch {
    my ($on_error, $on_warn, $file) = @_;
    my (@warnings, @ret);
    local $SIG{__WARN__} = sub { push @warnings, clean(shift) };
    my $sizer = Image::JPEG::Size->new(error => $on_error, warning => $on_warn);
    my $error //= eval { push @ret, $sizer->file_dimensions($file); 1 }
        ? undef : clean("$@");
    return $error, \@warnings, @ret;
}

is_deeply([catch(qw(quiet quiet), $invalid)],
          [undef, [], 0, 0],
          'error handling for quiet/quiet/invalid');

is_deeply([catch(qw(quiet warn), $invalid)],
          [undef, [$invalid_warning], 0, 0],
          'error handling for quiet/warn/invalid');

is_deeply([catch(qw(quiet fatal), $invalid)],
          [$invalid_warning, []],
          'error handling for quiet/fatal/invalid');

is_deeply([catch(qw(warn quiet), $invalid)],
          [undef, [$invalid_error], 0, 0],
          'error handling for warn/quiet/invalid');

is_deeply([catch(qw(warn warn), $invalid)],
          [undef, [$invalid_warning, $invalid_error], 0, 0],
          'error handling for warn/warn/invalid');

is_deeply([catch(qw(warn fatal), $invalid)],
          [$invalid_warning, []],
          'error handling for warn/fatal/invalid');

is_deeply([catch(qw(fatal quiet), $invalid)],
          [$invalid_error, []],
          'error handling for fatal/quiet/invalid');

is_deeply([catch(qw(fatal warn), $invalid)],
          [$invalid_error, [$invalid_warning]],
          'error handling for fatal/warn/invalid');

is_deeply([catch(qw(fatal fatal), $invalid)],
          [$invalid_warning, []],
          'error handling for fatal/fatal/invalid');

is_deeply([catch(qw(quiet quiet), $recoverable)],
          [undef, [], 2820, 3077],
          'error handling for quiet/quiet/recoverable');

is_deeply([catch(qw(quiet warn), $recoverable)],
          [undef, \@recoverable_warnings, 2820, 3077],
          'error handling for quiet/warn/recoverable');

is_deeply([catch(qw(quiet fatal), $recoverable)],
          [$recoverable_warnings[0], []],
          'error handling for quiet/fatal/recoverable');

is_deeply([catch(qw(warn quiet), $recoverable)],
          [undef, [], 2820, 3077],
          'error handling for warn/quiet/recoverable');

is_deeply([catch(qw(warn warn), $recoverable)],
          [undef, \@recoverable_warnings, 2820, 3077],
          'error handling for warn/warn/recoverable');

is_deeply([catch(qw(warn fatal), $recoverable)],
          [$recoverable_warnings[0], []],
          'error handling for warn/fatal/recoverable');

is_deeply([catch(qw(fatal quiet), $recoverable)],
          [undef, [], 2820, 3077],
          'error handling for fatal/quiet/recoverable');

is_deeply([catch(qw(fatal warn), $recoverable)],
          [undef, \@recoverable_warnings, 2820, 3077],
          'error handling for fatal/warn/recoverable');

is_deeply([catch(qw(fatal fatal), $recoverable)],
          [$recoverable_warnings[0], []],
          'error handling for fatal/fatal/recoverable');

is_deeply([catch(qw(warn warn), $dupe_errors)],
          [undef, \@deduped_warnings, 0, 0],
          'error handling for duplicate errors');

done_testing();
