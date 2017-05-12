use Test::More;
BEGIN
{
    eval "use Test::Pod";
    if ($@) {
        plan(skip_all => "Test::Pod is required to test POD") if $@;
    }
}

all_pod_files_ok();