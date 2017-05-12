use Cwd;
use File::Path;

unlink cwd().'/t/indexing_test.db';
File::Path::rmtree('./t/tmp_files');

