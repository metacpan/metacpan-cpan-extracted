module TransmitterWrapper
  extend FFI::Library

  arch = FFI::Platform::ARCH == 'x86_64' ? 'X64' : 'X86'

  if OS.linux?
    ffi_lib File.expand_path("../../../Binaries/Native/Linux/#{arch}/libJavonetRubyRuntimeNative.so", __FILE__)
  elsif OS.mac?
    ffi_lib File.expand_path("../../../Binaries/Native/MacOs/#{arch}/libJavonetRubyRuntimeNative.dylib", __FILE__)
  else
    RubyInstaller::Runtime.add_dll_directory(File.expand_path("../../../Binaries/Native/Windows/#{arch}/", __FILE__))
    ffi_lib File.expand_path("../../../Binaries/Native/Windows/#{arch}/JavonetRubyRuntimeNative.dll", __FILE__)
  end

  attach_function :SendCommand, [:pointer, :int], :int
  attach_function :ReadResponse, [:pointer, :int], :int
  attach_function :Activate, [:pointer, :pointer, :pointer, :pointer], :int
  attach_function :GetNativeError, [], :string
  attach_function :SetConfigSource, [:pointer], :int
end