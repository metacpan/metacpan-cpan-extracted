# frozen_string_literal: true
require_relative './runtime_name'

class RuntimeNameHandler
  def self.get_name(runtime_name)
    if runtime_name == RuntimeName::CLR
      return 'clr'
    end
    if runtime_name == RuntimeName::GO
      return 'go'
    end
    if runtime_name == RuntimeName::JVM
      return 'jvm'
    end
    if runtime_name == RuntimeName::NETCORE
      return 'netcore'
    end
    if runtime_name == RuntimeName::PERL
      return 'perl'
    end
    if runtime_name == RuntimeName::PYTHON
      return 'python'
    end
    if runtime_name == RuntimeName::RUBY
      return 'ruby'
    end
    if runtime_name == RuntimeName::NODEJS
      return 'nodejs'
    end
    if runtime_name == RuntimeName::CPP
      return 'cpp'
    end
  end
end
