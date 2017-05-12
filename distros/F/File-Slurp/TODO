
File::Slurp TODO

NEW FEATURES

prepend_file() -- prepend text to the front of a file

	options: lock file? enable atomic

edit_file() -- slurp into $_, call edit code block, write out $_

	options: lock file?

edit_file_lines()  -- slurp each line into $_, call edit code block,
	write out $_

	options: lock file?

read_file_lines()
	reads lines to array ref or list
	same as $list = read_file( $file, { array_ref => 1 } 
	or @lines = read_file()

new options for read_dir
	prepend -- prepend the dir name to each dir entry.
	filter -- grep dir entries with qr// or code ref.

BUGS:

restart sysread/write after a signal (or check i/o count)

FEATURE REQUESTS

