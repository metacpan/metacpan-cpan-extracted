use MooseX::Declare;

class ETLp::PluginTest::Test {
    sub type {
        return 'test';
    }
    method test (Str $filename) {
        return "test";
    }
}

class ETLp::PluginTest::Test2 {
    sub type {
        return 'test2';
    }
    method test (Str $filename) {
        return "test";
    }
}
1;


