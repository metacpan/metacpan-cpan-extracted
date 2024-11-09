class RuntimeLogger

  @not_logged_yet = true

  def self.get_runtime_info(get_loaded_modules)
    begin
      runtime_info = "Ruby Managed Runtime Info:\n".force_encoding('UTF-8') +
        "Ruby Version: #{RUBY_VERSION}\n".force_encoding('UTF-8') +
        "Ruby Implementation: #{RUBY_ENGINE}\n".force_encoding('UTF-8') +
        "Ruby Platform: #{RUBY_PLATFORM}\n".force_encoding('UTF-8') +
        "Ruby Engine: #{RUBY_ENGINE}\n".force_encoding('UTF-8') +
        "Ruby Engine Version: #{RUBY_ENGINE_VERSION}\n".force_encoding('UTF-8') +
        "Current Directory: #{Dir.pwd}\n".force_encoding('UTF-8') +
        "Ruby search path: " + $LOAD_PATH.join(", ").force_encoding('UTF-8') + "\n"
      if get_loaded_modules
        runtime_info += "Ruby loaded modules (excluding Javonet classes): " + $LOADED_FEATURES.reject { |feature| feature.include?("Binaries/Ruby") }.join(", ").force_encoding('UTF-8') + "\n"
      end
        return runtime_info
    rescue => e
      "Ruby Managed Runtime Info: Error while fetching runtime info".force_encoding('UTF-8')
    end
  end

  def self.print_runtime_info(get_loaded_modules = true)
    if @not_logged_yet
      puts get_runtime_info(get_loaded_modules)
      @not_logged_yet = false
    end
  end
end