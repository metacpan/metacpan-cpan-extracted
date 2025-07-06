use std::fmt;

#[derive(Debug, Clone)]
pub enum InlineLuaError {
    InitError(String),
    SetupError(String),
    EvalError(String),
    ExecError(String),
    FennelError(String),
    FennelNotEnabled,
    ConversionError(String),
    SetError(String),
    GetError(String),
    CleanupError(String),
}

impl fmt::Display for InlineLuaError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            InlineLuaError::InitError(msg)      => write!(f, "Initialization error: {}", msg),
            InlineLuaError::SetupError(msg)     => write!(f, "Setup error: {}", msg),
            InlineLuaError::EvalError(msg)      => write!(f, "Evaluation error: {}", msg),
            InlineLuaError::ExecError(msg)      => write!(f, "Execution error: {}", msg),
            InlineLuaError::FennelError(msg)    => write!(f, "Fennel error: {}", msg),
            InlineLuaError::FennelNotEnabled    => write!(f, "Fennel is not enabled"),
            InlineLuaError::ConversionError(msg)=> write!(f, "Conversion error: {}", msg),
            InlineLuaError::SetError(msg)       => write!(f, "Set error: {}", msg),
            InlineLuaError::GetError(msg)       => write!(f, "Get error: {}", msg),
            InlineLuaError::CleanupError(msg)   => write!(f, "Cleanup error: {}", msg),
        }
    }
}

impl std::error::Error for InlineLuaError {}
