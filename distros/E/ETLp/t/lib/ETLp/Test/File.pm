package ETLp::Test::File;

use Moose;
use Test::More;
use Data::Dumper;

BEGIN {
    extends qw(ETLp::Test::Base);
}

use ETLp::Config;
use ETLp::File::Config;
use ETLp::File::Read::CSV;
use ETLp::File::Validate;
use DateTime;
use FindBin qw($Bin);
use Try::Tiny;
use File::Slurp;
use File::Copy;

sub new_args {
    (
        keep_logger     => 0,
        create_log_file => 1
    );
}

sub config : Tests(13) {
    my $self = shift;

    my $file_def_dir = $self->file_def_dir;

    my $rule_conf = ETLp::File::Config->new(
        directory  => $file_def_dir,
        definition => 'file_def1.cfg'
    );

    isa_ok($rule_conf, 'ETLp::File::Config');

    my $parsed_config = {
        'cost' => {
            'nullable' => 'Y',
            'rule'     => 'integer',
        },
        'city' => {
            'nullable' => 'N',
            'rule'     => 'qr/^(Auckland|Wellington)$/',
        },
        'period' => {
            'nullable' => 'N',
            'rule'     => 'range(1,50)',
        },
        'rec_date' => {
            'nullable' => 'N',
            'rule'     => 'date(%Y-%m-%d %H:%M:%S)',
        },
        'custname' => {
            'nullable' => 'N',
            'rule'     => 'varchar(20)',
        },
        'phone' => {
            'nullable' => 'Y',
            'rule'     => 'qr/^\\d{3}-\\d{4}$/',
        }
    };

    my $fields = ['custname', 'cost', 'phone', 'city', 'rec_date', 'period'];

    is_deeply($rule_conf->rules, $parsed_config,     'Rules Parsed');
    is_deeply($fields,           $rule_conf->fields, 'Fields Parsed');

    try {
        $rule_conf = ETLp::File::Config->new(
            directory  => $file_def_dir,
            definition => 'file_def2.cfg'
        );
    }
    catch {
        like(
            $_,
            qr/Nullable must be Y or N.*value: B.*\line: city/s,
            'Invalid nullable'
        );
    };

    $rule_conf = ETLp::File::Config->new(
        directory  => $file_def_dir,
        definition => 'file_def3.cfg'
    );

    $parsed_config = {
        period => {
            'nullable' => 'N',
            'rule'     => ['range(1,50)', 'integer'],
        }
    };

    is_deeply($rule_conf->rules, $parsed_config, 'Multiple Rules');

    try {
        $rule_conf = ETLp::File::Config->new(
            directory  => $file_def_dir,
            definition => 'file_def4.cfg'
        );
    }
    catch {
        like($_, qr/^unknown rule flot/, "Unknown Rule");
    };

    $rule_conf =
      ETLp::File::Config->new(definition => $file_def_dir . '/file_def3.cfg');

    is_deeply($rule_conf->rules, $parsed_config, 'No Directory Specifier');

    my $log_file = $self->log_file_name();
    $rule_conf->logger->error('Logger test');

    my $log_text = read_file($log_file);

    like(
        $log_text,
        qr/\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2}.+ERROR> Logger test/,
        "Log content matches"
    );

    try {
        $rule_conf =
          ETLp::File::Config->new(
            definition => $file_def_dir . '/file_def7.cfg');
    }
    catch {
        like(
            $_,
            qr/error: EIF - Loose unescaped quote/,
            'Text::CSV Parse failure'
        );
        like(
            $_,
            qr/period     N    range\(1,50\); integer""/s,
            'Invalid Text::CSV rule'
        );
    };

    try {
        $rule_conf =
          ETLp::File::Config->new(
            definition => $file_def_dir . '/file_def8.cfg');
    }
    catch {
        like(
            $_,
qr/Config file must provide the field name, nullable flag and validation rule/,
            'Invalid Config'
        );
        like($_, qr/period     N/, 'Offending line');
    };

    try {
        $rule_conf =
          ETLp::File::Config->new(
            definition => $file_def_dir . '/nonexistent_file.cfg');
    }
    catch {
        like(
            $_,
            qr/Unable to open.+nonexistent_file.cfg: No such file or directory/,
            'Non existent file'
        );
    };

}

sub csv : Tests(9) {
    my $self = shift;

    my $csv_dir = $self->csv_dir();

    my $csv = ETLp::File::Read::CSV->new(
        directory => $csv_dir,
        filename  => 'scores.csv.loc',
        fields    => [qw/id name score/],
        localize  => 1
    );

    isa_ok($csv, 'ETLp::File::Read::CSV');
    can_ok($csv, 'get_fields', 'get_line', 'line_counter');

    my $records = [
        {
            'name'  => 'Smith',
            'score' => '50',
            'id'    => '1'
        },
        {
            'name'  => 'Jones',
            'score' => '30',
            'id'    => '2'
        },
        {
            'name'  => 'White',
            'score' => '89',
            'id'    => '3'
        },
        {
            'name'  => 'Brown',
            'score' => '73',
            'id'    => '4'
        }
    ];

    my @records;

    while (my $record = $csv->get_fields) {
        push @records, $record;
    }

    is_deeply($records, \@records, "Parse csv content");

    try {
        $csv = ETLp::File::Read::CSV->new(
            directory => $csv_dir,
            filename  => 'scores_bad.csv.loc',
            fields    => [qw/id name score/],
            localize  => 1
        );

        while (my $record = $csv->get_fields) { }
    }
    catch {
        my ($line_number) = (/line number:\s+(\d+)/s);
        my ($fields)      = (/fields: (\w+(?:,\s*\w+)*)/s);
        my ($line)        = (/line:\s*(\S+)/);
        like(
            $_,
qr/The number of data file fields does not match the number of control file fields/s,
            'Invalid record error'
        );

        is($line_number, 2,                 'Invalid record number');
        is($fields,      'id, name, score', 'Invalid record fields');
        is($line,        '2,Jones',         'Invalid record');
    };

    my $whitespace_records = [
        {
            'name'  => '  Smith  ',
            'score' => '50',
            'id'    => '1'
        },
        {
            'name'  => 'Jones ',
            'score' => '30',
            'id'    => '2'
        },
        {
            'name'  => 'White    ',
            'score' => '89',
            'id'    => '3'
        },
        {
            'name'  => 'Brown ',
            'score' => '73',
            'id'    => '4'
        }
    ];

    $csv = ETLp::File::Read::CSV->new(
        directory => $csv_dir,
        filename  => 'scores_whitespace.csv.loc',
        fields    => [qw/id name score/],
        localize  => 1
    );

    @records = ();

    while (my $record = $csv->get_fields) {
        push @records, $record;
    }

    is_deeply($whitespace_records, \@records, "Whitespace csv content");

    # Testing the passing of Text::CSV parameters. No need to do more than one.
    # Simply trim the whitespace
    $csv = ETLp::File::Read::CSV->new(
        directory   => $csv_dir,
        filename    => 'scores_whitespace.csv.loc',
        fields      => [qw/id name score/],
        csv_options => {allow_whitespace => 1},
        localize    => 1
    );

    @records = ();

    while (my $record = $csv->get_fields) {
        push @records, $record;
    }

    is_deeply($records, \@records, "Process Text::CSV parameter");
}

sub validate : Tests(7) {
    my $self         = shift;
    my $csv_dir      = $self->csv_dir();
    my $file_def_dir = $self->file_def_dir();

    my $validator = ETLp::File::Validate->new(
        data_directory        => $csv_dir,
        file_config_directory => $file_def_dir,
        file_definition       => 'file_def1.cfg',
        localize              => 1,
        type                  => 'csv'
    );

    isa_ok($validator, 'ETLp::File::Validate');

    try {
        my $validator = ETLp::File::Validate->new(
            data_directory        => $csv_dir,
            file_config_directory => $file_def_dir,
            file_definition       => 'file_def1.cfg',
            localize              => 1,
            type                  => 'xxx'
        );
        $validator->validate('v1.csv');
    }
    catch {
        like($_, qr/Unknown file type: xxx/, 'Unknown file type');
    };

    ok($validator->validate('v1.csv.loc') eq '1', 'Valid File');
    ok($validator->validate('v2.csv.loc') eq '0', 'Invalid File');

    my $errors = [
        {
            'line_number' => 2,
            'field_value' => '(09) 444-3456',
            'field_name'  => 'phone',
            'message'     => 'Value does not match pattern qr/^\\d{3}-\\d{4}$/'
        },
        {
            'line_number' => 3,
            'field_value' => '2008-13-12 12:00:03',
            'field_name'  => 'rec_date',
            'message'     => 'Invalid date for pattern: %Y-%m-%d %H:%M:%S'
        },
        {
            'line_number' => 4,
            'field_value' => 51,
            'field_name'  => 'period',
            'message'     => 'Value outside of range: range(1,50)'
        },
        {
            'line_number' => 5,
            'field_value' => 'Roger Ramjet III, Esquire',
            'field_name'  => 'custname',
            'message' => 'Length must be less than or equal to 20 characters'
        },
        {
            'line_number' => 6,
            'field_value' => '',
            'field_name'  => 'custname',
            'message'     => 'Mandatory field missing value'
        },
        {
            'line_number' => 8,
            'field_value' => '12.99',
            'field_name'  => 'cost',
            'message'     => 'Value must be an integer'
        }
    ];

    is_deeply($validator->get_errors, $errors, 'General Validation Errors');

    $validator = ETLp::File::Validate->new(
        data_directory        => $csv_dir,
        file_config_directory => $file_def_dir,
        file_definition       => 'file_def5.cfg',
        localize              => 1,
        type                  => 'csv'
    );

    $validator->validate('v3.csv.loc');
    $errors = [
        {
            'line_number' => 2,
            'field_value' => 99,
            'field_name'  => 'val1',
            'message'     => 'Value outside of range: range(1,50)'
        },
        {
            'line_number' => 3,
            'field_value' => 41,
            'field_name'  => 'val2',
            'message'     => 'Value must be <= 40'
        },
        {
            'line_number' => 5,
            'field_value' => 18,
            'field_name'  => 'val3',
            'message'     => 'Value must_be >= 19'
        },
        {
            'line_number' => 6,
            'field_value' => 'a',
            'field_name'  => 'val1',
            'message'     => 'Value must be an a number'
        }
    ];

    is_deeply($validator->get_errors, $errors, 'Range Validation Errors');

    $validator = ETLp::File::Validate->new(
        data_directory        => $csv_dir,
        file_config_directory => $file_def_dir,
        file_definition       => 'file_def6.cfg',
        localize              => 1,
        type                  => 'csv'
    );

    $errors = [
        {
            'line_number' => 2,
            'field_value' => '99.9',
            'field_name'  => 'val1',
            'message'     => 'Value must be an integer'
        },
        {
            'line_number' => 4,
            'field_value' => 'a',
            'field_name'  => 'val2',
            'message'     => 'Value must be a floating number'
        },
        {
            'line_number' => 5,
            'field_value' => 'a',
            'field_name'  => 'val1',
            'message'     => 'Value must be an integer'
        }
    ];

    $validator->validate('v4.csv.loc');

    is_deeply($validator->get_errors, $errors, 'Invalid Number Errors');
}

1;
