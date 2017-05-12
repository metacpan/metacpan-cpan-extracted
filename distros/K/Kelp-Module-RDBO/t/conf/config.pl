use File::Temp 'tempfile';

my ( $fh,  $tempfile )  = tempfile();
my ( $fh2, $tempfile2 ) = tempfile();

{
    modules      => [qw/RDBO/],
    modules_init => {
        RDBO => {
            prefix       => 'MyApp::DB',
            default_type => 'main',
            source       => [
                {
                    type     => 'main',
                    driver   => 'SQLite',
                    database => $tempfile
                },
                {
                    type     => 'other',
                    driver   => 'SQLite',
                    database => $tempfile2
                }
            ],
        },
    }
};
