use Module::Build;

Module::Build->new(
		   module_name => 'Lego::Ldraw',
		   license => 'perl',
		   requires => {
				'Template' => 0,
				'Math::Trig' => 0,
				'Math::VectorReal' => 0,
				'Math::MatrixReal' => 0,
				'YAML' => 0,
			       },
		  )->create_build_script;
