package Games::Lacuna::Task::Action::EmpireReport;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Module::Pluggable 
    search_path => ['Games::Lacuna::Task::Report'],
    sub_name => 'all_reports';

use Moose;
extends qw(Games::Lacuna::Task::Action);
with 'Games::Lacuna::Task::Role::Notify',all_reports();

use Games::Lacuna::Task::Table;
use Moose::Util::TypeConstraints;
use Games::Lacuna::Task::Utils qw(pretty_dump class_to_name);
use IO::Interactive qw(is_interactive);

subtype 'Lacuna::Task::Type::Output' 
    => as enum([qw(email stdout)])
    => message { "Not a valid output type '$_'" };

has 'report' => (
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    documentation   => 'Specifies which sub-reports to include in the empire report',
    default         => sub { 
        [ map { class_to_name($_) } all_reports() ]
    },
);

has 'output' => (
    is              => 'rw',
    isa             => 'Lacuna::Task::Type::Output',
    documentation   => 'Specifies how the report should be presented to the user [Options: email, stdout]',
    default         => sub { 
        if (is_interactive) {
            return 'stdout';
        } else {
            return 'email';
        }
    },
);

sub description {
    return q[Generate an informative empire status report];
}

sub run {
    my ($self) = @_;
    
    my $empire_name = $self->empire_name;

    my $report_html = join '',<DATA>;
    my @report_tables;
    foreach my $report (@{$self->report}) {
        my $method = 'report_'.$report;
        foreach my $report_data ($self->$method()) {
            push(@report_tables,$report_data);
        }
    }
    
    given ($self->output) {
        when ('email') {
            my $report_content =
                join "\n",
                map { $_->render_html() } 
                @report_tables;
            $report_html =~ s/\@REPORT\@/$report_content/g;
            
            $self->notify(
                "[$empire_name] Status report",
                $report_html
            );
        }
        when ('stdout') {
            my $report_content =
                join "\n",
                map { $_->render_text() } 
                @report_tables;
            say $report_content;
        }
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__DATA__
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
    <title>Empire Report</title>
    <style type="text/css">
    th {
        border-bottom: 2px solid;
    }
    tr {
        border-bottom: 1px solid grey;
    }
    </style>
</head>
<body>
@REPORT@
</body>
</html>