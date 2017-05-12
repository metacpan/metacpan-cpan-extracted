
package Docserver::Config;
%Docserver::Config::Config =
	(
	'port'		=>	5455,
	'clients'	=>	[
					{
					'mask' => '^127\.0\.0\.1$',
					'accept' => 1,
					},
					{
					'mask' => '\.fi\.muni\.cz$',
					'accept' => 1,
					},
				],

	'tmp_dir'	=>	'C:\\tmp\\docserver.tmp',
	'ChunkSize'	=>	128 * 512,
	'ps'		=>	'Generic PostScript Printer on FILE:',
	### 'ps'		=> 	'Adobe Generic PS on FILE:',
	'ps1'		=>	'Adobe Generic PS1 on FILE:',
	'excel.ps'	=>	'Adobe Generic PS na FILE:',
	'excel.ps1'	=>	'Adobe Generic PS1 na FILE:',
	# Excel variants are here in case Excel names differ from the
	# Word ones. If they are not here, base ps and ps1 will be
	# used.
	'pidfile'	=>	'docserver.pid',
	'logfile'	=>	1,
	);

