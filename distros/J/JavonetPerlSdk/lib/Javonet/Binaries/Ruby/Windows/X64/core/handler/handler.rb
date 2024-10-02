require_relative '../../utils/runtime_name'
require_relative '../../utils/command_type'
require_relative '../../core/handler/handler_dictionary'
require_relative '../../core/handler/abstract_handler'
require_relative '../../core/handler/value_handler'
require_relative '../../core/handler/load_library_handler'
require_relative '../../core/handler/invoke_static_method_handler'
require_relative '../../core/handler/get_static_field_handler'
require_relative '../../core/handler/get_instance_field_handler'
require_relative '../../core/handler/set_instance_field_handler'
require_relative '../../core/handler/create_class_instance_handler'
require_relative '../../core/handler/set_static_field_handler'
require_relative '../../core/handler/get_type_handler'
require_relative '../../core/handler/invoke_instance_method_handler'
require_relative '../../core/handler/resolve_instance_handler'
require_relative '../../core/handler/casting_handler'
require_relative '../../core/handler/destruct_reference_handler'
require_relative '../../core/handler/array_get_item_handler'
require_relative '../../core/handler/array_get_size_handler'
require_relative '../../core/handler/array_get_rank_handler'
require_relative '../../core/handler/array_set_item_handler'
require_relative '../../core/handler/array_handler'
require_relative '../../core/handler/enable_namespace_handler'
require_relative '../../core/handler/enable_type_handler'
require_relative '../../core/reference_cache/references_cache'
require_relative '../../utils/exceptions/exception_serializer'


class Handler < AbstractHandler

  def initialize
    super
    value_handler = ValueHandler.new
    load_library_handler = LoadLibraryHandler.new
    invoke_static_method_handler = InvokeStaticMethodHandler.new
    get_static_field_handler = GetStaticFieldHandler.new
    get_class_instance_handler = CreateClassInstanceHandler.new
    set_static_field_handler = SetStaticFieldHandler.new
    get_type_handler = GetTypeHandler.new
    invoke_instance_method_handler = InvokeInstanceMethodHandler.new
    resolve_instance_handler = ResolveInstanceHandler.new
    casting_handler = CastingHandler.new
    get_instance_field_handler = GetInstanceFieldHandler.new
    set_instance_field_handler = SetInstanceFieldHandler.new
    destruct_reference_handler = DestructReferenceHandler.new
    array_get_item_handler = ArrayGetItemHandler.new
    array_get_size_handler = ArrayGetSizeHandler.new
    array_get_rank_handler = ArrayGetRankHandler.new
    array_set_item_handler = ArraySetItemHandler.new
    array_handler = ArrayHandler.new
    enable_namespace_handler = EnableNamespaceHandler.new
    enable_type_handler = EnableTypeHandler.new


    $handler_dict[CommandType::VALUE] = value_handler
    $handler_dict[CommandType::LOAD_LIBRARY] = load_library_handler
    $handler_dict[CommandType::INVOKE_STATIC_METHOD] = invoke_static_method_handler
    $handler_dict[CommandType::GET_STATIC_FIELD] = get_static_field_handler
    $handler_dict[CommandType::CREATE_CLASS_INSTANCE] = get_class_instance_handler
    $handler_dict[CommandType::SET_STATIC_FIELD] = set_static_field_handler
    $handler_dict[CommandType::GET_TYPE] = get_type_handler
    $handler_dict[CommandType::INVOKE_INSTANCE_METHOD] = invoke_instance_method_handler
    $handler_dict[CommandType::REFERENCE] = resolve_instance_handler
    $handler_dict[CommandType::CAST] = casting_handler
    $handler_dict[CommandType::GET_INSTANCE_FIELD] = get_instance_field_handler
    $handler_dict[CommandType::SET_INSTANCE_FIELD] = set_instance_field_handler
    $handler_dict[CommandType::DESTRUCT_REFERENCE] = destruct_reference_handler
    $handler_dict[CommandType::ARRAY_GET_ITEM] = array_get_item_handler
    $handler_dict[CommandType::ARRAY_GET_SIZE] = array_get_size_handler
    $handler_dict[CommandType::ARRAY_GET_RANK] = array_get_rank_handler
    $handler_dict[CommandType::ARRAY_SET_ITEM] = array_set_item_handler
    $handler_dict[CommandType::ARRAY] = array_handler
    $handler_dict[CommandType::ENABLE_NAMESPACE] = enable_namespace_handler
    $handler_dict[CommandType::ENABLE_TYPE] = enable_type_handler
  end


  def handle_command(command)
    if command.command_type == CommandType::RETRIEVE_ARRAY
      response_array = $handler_dict[CommandType::REFERENCE].handle_command(command.payload[0])
      return Command.create_array_response(response_array, command.runtime_name)
    end
    response = $handler_dict[command.command_type].handle_command(command)
      if is_response_nil(response) || is_response_simple_type(response)
        Command.create_response(response, command.runtime_name)
      elsif response.is_a? Exception
        return ExceptionSerializer.serialize_exception(response, command)
      else
        reference_cache = ReferencesCache.instance
        guid = reference_cache.cache_reference(response)
        Command.create_reference(guid, command.runtime_name)
      end
  end

  def is_response_simple_type(response)
    (response.is_a? String or response.is_a? Float or response.is_a? Integer or response.is_a? TrueClass or response.is_a? FalseClass)
  end

  def is_response_nil(response)
    response.nil?
  end

  def is_response_array(response)
    response.is_a? Array
  end


end
